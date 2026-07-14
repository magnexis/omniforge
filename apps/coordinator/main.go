package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync/atomic"
	"time"
)

func sanitizedSystemPath() string {
	raw := strings.Split(os.Getenv("PATH"), ";")
	filtered := make([]string, 0, len(raw))
	for _, entry := range raw {
		entry = strings.TrimSpace(entry)
		if entry == "" {
			continue
		}
		lower := strings.ToLower(entry)
		if strings.Contains(lower, `wingtk.gvsbuild.gtk4`) {
			continue
		}
		filtered = append(filtered, entry)
	}
	return strings.Join(filtered, ";")
}

func buildWorkerPath() string {
	segments := []string{
		`C:\Program Files\Erlang OTP\bin`,
		`C:\Program Files (x86)\scala\bin`,
		`C:\Program Files (x86)\FreeBASIC`,
		`C:\Program Files (x86)\gforth`,
		`C:\Users\matth\AppData\Local\Programs\Crystal`,
		`C:\Users\matth\AppData\Local\Programs\GNU Octave\Octave-11.3.0\mingw64\bin`,
		`C:\Users\matth\AppData\Local\Programs\Julia-1.12.6\bin`,
		`C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\Gleam.Gleam_Microsoft.Winget.Source_8wekyb3d8bbwe`,
		`C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\elves.elvish_Microsoft.Winget.Source_8wekyb3d8bbwe`,
		`C:\Users\matth\AppData\Local\Programs\nu\bin`,
		sanitizedSystemPath(),
	}
	return strings.Join(segments, ";")
}

type Capability struct {
	Name         string `json:"name"`
	InputSchema  string `json:"inputSchema,omitempty"`
	OutputSchema string `json:"outputSchema,omitempty"`
}

type WorkerManifest struct {
	ID            string       `json:"id"`
	Language      string       `json:"language"`
	Runtime       string       `json:"runtime"`
	WorkerVersion string       `json:"workerVersion"`
	Tier          string       `json:"tier"`
	WorkingDirectory string    `json:"workingDirectory,omitempty"`
	Command       []string     `json:"command"`
	Capabilities  []Capability `json:"capabilities"`
}

type Message struct {
	Type         string         `json:"type"`
	Protocol     string         `json:"protocol,omitempty"`
	MessageID    string         `json:"messageId,omitempty"`
	ParentMessageID string      `json:"parentMessageId,omitempty"`
	WorkerID     string         `json:"workerId,omitempty"`
	Language     string         `json:"language,omitempty"`
	Runtime      string         `json:"runtimeVersion,omitempty"`
	WorkerVersion string        `json:"workerVersion,omitempty"`
	Capabilities []Capability   `json:"capabilities,omitempty"`
	Limits       map[string]any `json:"limits,omitempty"`
	JobID        string         `json:"jobId,omitempty"`
	Capability   string         `json:"capability,omitempty"`
	Input        any            `json:"input,omitempty"`
	Output       any            `json:"output,omitempty"`
	Error        string         `json:"error,omitempty"`
	Details      any            `json:"details,omitempty"`
	Progress     float64        `json:"progress,omitempty"`
	Status       string         `json:"status,omitempty"`
	Reason       string         `json:"reason,omitempty"`
	Severity     string         `json:"severity,omitempty"`
	LogMessage   string         `json:"message,omitempty"`
	Metadata     map[string]any `json:"metadata,omitempty"`
}

type JobRequest struct {
	Capability string `json:"capability"`
	Language   string `json:"language,omitempty"`
	Input      any    `json:"input"`
	CancelAfterMs int `json:"cancelAfterMs,omitempty"`
}

type PipelineStep struct {
	Capability string `json:"capability"`
	Language   string `json:"language,omitempty"`
}

type PipelineDefinition struct {
	Name  string         `json:"name"`
	Steps []PipelineStep `json:"steps"`
}

type WorkerConnection struct {
	manifest WorkerManifest
	cmd      *exec.Cmd
	stdin    *bufio.Writer
	stdinPipe io.Closer
	stdout   *bufio.Scanner
}

type WorkerStatus struct {
	ID             string       `json:"workerId"`
	Language       string       `json:"language"`
	RuntimeVersion string       `json:"runtimeVersion"`
	WorkerVersion  string       `json:"workerVersion"`
	Capabilities   []Capability `json:"capabilities"`
	Status         string       `json:"status"`
	SuccessRate    float64      `json:"successRate"`
	FailureRate    float64      `json:"failureRate"`
	AverageRuntime float64      `json:"averageRuntimeMs"`
	LastHeartbeat  string       `json:"lastHeartbeat"`
	Tier           string       `json:"tier"`
}

type RunResult struct {
	WorkerID   string         `json:"workerId"`
	Language   string         `json:"language"`
	Capability string         `json:"capability"`
	Output     any            `json:"output"`
	Reason     []string       `json:"reason"`
	ElapsedMs  float64        `json:"elapsedMs"`
}

type PipelineResult struct {
	Name         string          `json:"name"`
	Steps        []RunResult     `json:"steps"`
	FinalOutput  any             `json:"finalOutput"`
	Artifacts    map[string]any  `json:"artifacts"`
}

var jobCounter uint64

func rootDir() string {
	cwd, _ := os.Getwd()
	return filepath.Clean(filepath.Join(cwd, "..", ".."))
}

func loadWorkerManifests(root string) ([]WorkerManifest, error) {
	workerRoot := filepath.Join(root, "workers")
	entries, err := os.ReadDir(workerRoot)
	if err != nil {
		return nil, err
	}
	var manifests []WorkerManifest
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		path := filepath.Join(workerRoot, entry.Name(), "worker.json")
		raw, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		var manifest WorkerManifest
		if err := json.Unmarshal(raw, &manifest); err != nil {
			return nil, err
		}
		manifests = append(manifests, manifest)
	}
	sort.Slice(manifests, func(i, j int) bool { return manifests[i].ID < manifests[j].ID })
	return manifests, nil
}

func prepareWorker(root string, manifest WorkerManifest) error {
	switch manifest.Language {
	case "java":
		cmd := exec.Command("javac", "Worker.java")
		cmd.Dir = filepath.Join(root, "workers", "java")
		cmd.Env = append(os.Environ(),
			fmt.Sprintf("GOCACHE=%s", filepath.Join(root, ".cache", "go", "build")),
			fmt.Sprintf("GOMODCACHE=%s", filepath.Join(root, ".cache", "go", "pkg")),
		)
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("javac failed: %s", strings.TrimSpace(string(output)))
		}
	case "c":
		cmd := exec.Command("clang", "worker.c", "-o", "worker.exe")
		cmd.Dir = filepath.Join(root, "workers", "c")
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("clang failed: %s", strings.TrimSpace(string(output)))
		}
	case "cpp":
		cmd := exec.Command("clang++", "worker.cpp", "-std=c++20", "-o", "worker.exe")
		cmd.Dir = filepath.Join(root, "workers", "cpp")
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("clang++ failed: %s", strings.TrimSpace(string(output)))
		}
	case "csharp":
		cmd := exec.Command("dotnet", "build", "Worker.csproj", "-nologo")
		cmd.Dir = filepath.Join(root, "workers", "csharp")
		cmd.Env = append(os.Environ(),
			"DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1",
			"DOTNET_CLI_TELEMETRY_OPTOUT=1",
			fmt.Sprintf("DOTNET_CLI_HOME=%s", filepath.Join(root, ".cache", "dotnet")),
			fmt.Sprintf("APPDATA=%s", filepath.Join(root, ".cache", "appdata")),
			fmt.Sprintf("NUGET_PACKAGES=%s", filepath.Join(root, ".cache", "nuget-packages")),
		)
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("dotnet build failed: %s", strings.TrimSpace(string(output)))
		}
	case "fsharp":
		cmd := exec.Command("dotnet", "build", "Worker.fsproj", "-nologo")
		cmd.Dir = filepath.Join(root, "workers", "fsharp")
		cmd.Env = append(os.Environ(),
			"DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1",
			"DOTNET_CLI_TELEMETRY_OPTOUT=1",
			fmt.Sprintf("DOTNET_CLI_HOME=%s", filepath.Join(root, ".cache", "dotnet")),
			fmt.Sprintf("APPDATA=%s", filepath.Join(root, ".cache", "appdata")),
			fmt.Sprintf("NUGET_PACKAGES=%s", filepath.Join(root, ".cache", "nuget-packages")),
		)
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("dotnet build failed: %s", strings.TrimSpace(string(output)))
		}
	case "vb":
		cmd := exec.Command("dotnet", "build", "Worker.vbproj", "-nologo")
		cmd.Dir = filepath.Join(root, "workers", "vb")
		cmd.Env = append(os.Environ(),
			"DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1",
			"DOTNET_CLI_TELEMETRY_OPTOUT=1",
			fmt.Sprintf("DOTNET_CLI_HOME=%s", filepath.Join(root, ".cache", "dotnet")),
			fmt.Sprintf("APPDATA=%s", filepath.Join(root, ".cache", "appdata")),
			fmt.Sprintf("NUGET_PACKAGES=%s", filepath.Join(root, ".cache", "nuget-packages")),
		)
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("dotnet build failed: %s", strings.TrimSpace(string(output)))
		}
	case "zig":
		if _, err := os.Stat(filepath.Join(root, "workers", "zig", "worker.exe")); err == nil {
			return nil
		}
		cmd := exec.Command(resolveExecutable(root, "zig"), "build-exe", "worker.zig", "-femit-bin=worker.exe")
		cmd.Dir = filepath.Join(root, "workers", "zig")
		cmd.Env = append(os.Environ(),
			fmt.Sprintf("ZIG_LOCAL_CACHE_DIR=%s", filepath.Join(root, ".cache", "zig", "local")),
			fmt.Sprintf("ZIG_GLOBAL_CACHE_DIR=%s", filepath.Join(root, ".cache", "zig", "global")),
		)
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("zig build failed: %s", strings.TrimSpace(string(output)))
		}
	case "nim":
		if _, err := os.Stat(filepath.Join(root, "workers", "nim", "worker.exe")); err == nil {
			return nil
		}
		cmd := exec.Command(resolveExecutable(root, "nim"), "c", "--cc:clang", "-d:release", "-o:worker.exe", "worker.nim")
		cmd.Dir = filepath.Join(root, "workers", "nim")
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("nim build failed: %s", strings.TrimSpace(string(output)))
		}
	case "d":
		if _, err := os.Stat(filepath.Join(root, "workers", "d", "worker.exe")); err == nil {
			return nil
		}
		cmd := exec.Command(resolveExecutable(root, "dmd"), "worker.d", "-of=worker.exe")
		cmd.Dir = filepath.Join(root, "workers", "d")
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("dmd build failed: %s", strings.TrimSpace(string(output)))
		}
	case "scala":
		return nil
	case "pascal":
		if _, err := os.Stat(filepath.Join(root, "workers", "pascal", "worker.exe")); err == nil {
			return nil
		}
		cmd := exec.Command(resolveExecutable(root, "fpc"), "worker.pas", "-oworker.exe")
		cmd.Dir = filepath.Join(root, "workers", "pascal")
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("fpc failed: %s", strings.TrimSpace(string(output)))
		}
	case "crystal":
		if _, err := os.Stat(filepath.Join(root, "workers", "crystal", "worker.ps1")); err == nil {
			return nil
		}
		return nil
	case "freebasic":
		if _, err := os.Stat(filepath.Join(root, "workers", "freebasic", "worker.exe")); err == nil {
			return nil
		}
		cmd := exec.Command(resolveExecutable(root, "fbc"), "worker.bas", "-x", "worker.exe")
		cmd.Dir = filepath.Join(root, "workers", "freebasic")
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("fbc build failed: %s", strings.TrimSpace(string(output)))
		}
	}
	return nil
}

func resolveExecutable(root, name string) string {
	if name == "lua" {
		luaPath := `C:\Users\matth\AppData\Local\Programs\Lua\bin\lua.exe`
		if _, err := os.Stat(luaPath); err == nil {
			return luaPath
		}
	}
	if name == "dart" {
		shim := filepath.Join(root, ".cache", "runtime-shims", "dart-sdk", "bin", "dart.exe")
		if _, err := os.Stat(shim); err == nil {
			return shim
		}
		return `C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\Google.DartSDK_Microsoft.Winget.Source_8wekyb3d8bbwe\dart-sdk\bin\dart.exe`
	}
	if name == "zig" {
		shim := filepath.Join(root, ".cache", "runtime-shims", "zig", "zig.exe")
		if _, err := os.Stat(shim); err == nil {
			return shim
		}
		return `C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\zig.zig_Microsoft.Winget.Source_8wekyb3d8bbwe\zig-x86_64-windows-0.16.0\zig.exe`
	}
	if name == "scala" {
		scalaPath := `C:\Program Files (x86)\scala\bin\scala.bat`
		if _, err := os.Stat(scalaPath); err == nil {
			return scalaPath
		}
	}
	if name == "scalac" {
		scalacPath := `C:\Program Files (x86)\scala\bin\scalac.bat`
		if _, err := os.Stat(scalacPath); err == nil {
			return scalacPath
		}
	}
	if name == "powershell" {
		return `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
	}
	if name == "perl" {
		return `C:\Program Files\Git\usr\bin\perl.exe`
	}
	if name == "racket" {
		return `C:\Program Files\Racket\Racket.exe`
	}
	if name == "swipl" {
		return `C:\Program Files\swipl\bin\swipl.exe`
	}
	if name == "escript" {
		return `C:\Program Files\Erlang OTP\bin\escript.exe`
	}
	if name == "nim" {
		shim := filepath.Join(root, ".cache", "runtime-shims", "nim.exe")
		if _, err := os.Stat(shim); err == nil {
			return shim
		}
		return `C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\nim.nim_Microsoft.Winget.Source_8wekyb3d8bbwe\nim-2.0.8\bin\nim.exe`
	}
	if name == "julia" {
		return `C:\Users\matth\AppData\Local\Programs\Julia-1.12.6\bin\julia.exe`
	}
	if name == "octave-cli" {
		return `C:\Users\matth\AppData\Local\Programs\GNU Octave\Octave-11.3.0\mingw64\bin\octave-cli.exe`
	}
	if name == "groovy" {
		return `C:\Program Files (x86)\Groovy\bin\groovy.bat`
	}
	if name == "Rscript" {
		return `C:\Program Files\R\R-4.6.1\bin\Rscript.exe`
	}
	if name == "bb" {
		shim := filepath.Join(root, ".cache", "runtime-shims", "bb.exe")
		if _, err := os.Stat(shim); err == nil {
			return shim
		}
		return `C:\Users\matth\AppData\Local\Microsoft\WinGet\Packages\Babashka.Babashka_Microsoft.Winget.Source_8wekyb3d8bbwe\bb.exe`
	}
	if name == "tclsh" {
		return `C:\Program Files\Git\mingw64\bin\tclsh.exe`
	}
	if name == "dmd" {
		return `C:\D\dmd2\windows\bin64\dmd.exe`
	}
	if name == "fbc" {
		return `C:\Program Files (x86)\FreeBASIC\fbc.exe`
	}
	if name == "fpc" {
		return `C:\FPC\3.2.2\bin\i386-win32\fpc.exe`
	}
	if name == "raku" {
		return `C:\Program Files\Rakudo\bin\raku.exe`
	}
	if name == "sbcl" {
		return `C:\Program Files\Steel Bank Common Lisp\sbcl.exe`
	}
	if name == "nu" {
		return `C:\Users\matth\AppData\Local\Programs\nu\bin\nu.exe`
	}
	if name == "gforth" {
		return `C:\Program Files (x86)\gforth\gforth.exe`
	}
	if name == "crystal" {
		return `C:\Users\matth\AppData\Local\Programs\Crystal\crystal.exe`
	}
	if name == "bash" {
		return `C:\Program Files\Git\usr\bin\bash.exe`
	}
	if name == "sh" {
		return `C:\Program Files\Git\bin\sh.exe`
	}
	if name == "awk" {
		return `C:\Program Files\Git\usr\bin\awk.exe`
	}
	if name == "cmd" {
		return `C:\Windows\System32\cmd.exe`
	}
	if filepath.IsAbs(name) {
		return name
	}
	if strings.HasPrefix(name, "workers/") || strings.HasPrefix(name, "apps/") {
		return filepath.Join(root, filepath.FromSlash(name))
	}
	return name
}

func startWorker(root string, manifest WorkerManifest) (*WorkerConnection, error) {
	if len(manifest.Command) == 0 {
		return nil, errors.New("worker manifest missing command")
	}
	command := make([]string, len(manifest.Command))
	copy(command, manifest.Command)
	command[0] = resolveExecutable(root, command[0])
	workerDir := root
	if manifest.WorkingDirectory != "" {
		workerDir = filepath.Join(root, filepath.FromSlash(manifest.WorkingDirectory))
	}
	if !filepath.IsAbs(command[0]) && strings.Contains(command[0], ".exe") {
		command[0] = filepath.Join(workerDir, command[0])
	}
	if err := prepareWorker(root, manifest); err != nil {
		return nil, err
	}
	_ = os.MkdirAll(filepath.Join(root, ".cache", "dotnet"), 0o755)
	_ = os.MkdirAll(filepath.Join(root, ".cache", "appdata", "NuGet"), 0o755)
	_ = os.MkdirAll(filepath.Join(root, ".cache", "nuget-packages"), 0o755)
	_ = os.MkdirAll(filepath.Join(root, ".cache", "crystal"), 0o755)
	_ = os.MkdirAll(filepath.Join(root, ".cache", "zig", "local"), 0o755)
	_ = os.MkdirAll(filepath.Join(root, ".cache", "zig", "global"), 0o755)
	_ = os.MkdirAll(`C:\tmp\omniforge-crystal-cache`, 0o755)
	_ = os.WriteFile(filepath.Join(root, ".cache", "appdata", "NuGet", "NuGet.Config"), []byte("<configuration />\n"), 0o644)
	cmd := exec.Command(command[0], command[1:]...)
	cmd.Dir = workerDir
	cmd.Env = append(os.Environ(),
		"LC_ALL=C",
		fmt.Sprintf("PATH=%s", buildWorkerPath()),
		"DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1",
		"DOTNET_CLI_TELEMETRY_OPTOUT=1",
		fmt.Sprintf("DOTNET_CLI_HOME=%s", filepath.Join(root, ".cache", "dotnet")),
		fmt.Sprintf("APPDATA=%s", filepath.Join(root, ".cache", "appdata")),
		fmt.Sprintf("NUGET_PACKAGES=%s", filepath.Join(root, ".cache", "nuget-packages")),
		fmt.Sprintf("GOCACHE=%s", filepath.Join(root, ".cache", "go", "build")),
		fmt.Sprintf("GOMODCACHE=%s", filepath.Join(root, ".cache", "go", "pkg")),
		fmt.Sprintf("ZIG_LOCAL_CACHE_DIR=%s", filepath.Join(root, ".cache", "zig", "local")),
		fmt.Sprintf("ZIG_GLOBAL_CACHE_DIR=%s", filepath.Join(root, ".cache", "zig", "global")),
	)

	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		return nil, err
	}
	stdinPipe, err := cmd.StdinPipe()
	if err != nil {
		return nil, err
	}
	if err := cmd.Start(); err != nil {
		return nil, err
	}

	var stderr bytes.Buffer
	go func() {
		scanner := bufio.NewScanner(stderrPipe)
		for scanner.Scan() {
			stderr.WriteString(scanner.Text())
			stderr.WriteString("\n")
		}
	}()

	conn := &WorkerConnection{
		manifest: manifest,
		cmd:      cmd,
		stdin:    bufio.NewWriter(stdinPipe),
		stdinPipe: stdinPipe,
		stdout:   bufio.NewScanner(stdoutPipe),
	}

	helloID := fmt.Sprintf("hello-%d", atomic.AddUint64(&jobCounter, 1))
	if err := conn.send(Message{Type: "HELLO", Protocol: "ofp/1", MessageID: helloID}); err != nil {
		return nil, err
	}
	for {
		msg, err := conn.receive()
		if err != nil {
			return nil, err
		}
		if msg.Type == "WELCOME" {
			continue
		}
		if msg.Type != "REGISTER" {
			return nil, fmt.Errorf("expected REGISTER from %s, got %s: %s", manifest.ID, msg.Type, stderr.String())
		}
		if err := conn.send(Message{
			Type:            "REGISTER_ACK",
			Protocol:        "ofp/1",
			ParentMessageID: msg.MessageID,
			WorkerID:        manifest.ID,
			Status:          "accepted",
			Metadata:        map[string]any{"scheduler": "local-first"},
		}); err != nil {
			return nil, err
		}
		break
	}
	return conn, nil
}

func (c *WorkerConnection) send(msg Message) error {
	raw, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	if _, err := c.stdin.Write(append(raw, '\n')); err != nil {
		return err
	}
	return c.stdin.Flush()
}

func (c *WorkerConnection) receive() (Message, error) {
	for c.stdout.Scan() {
		raw := bytes.TrimSpace(c.stdout.Bytes())
		if len(raw) == 0 {
			continue
		}
		var msg Message
		if err := json.Unmarshal(raw, &msg); err != nil {
			continue
		}
		return msg, nil
	}
	return Message{}, errors.New("worker closed stdout")
}

func (c *WorkerConnection) shutdown() {
	_ = c.send(Message{Type: "SHUTDOWN", Protocol: "ofp/1"})
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			msg, err := c.receive()
			if err != nil {
				return
			}
			if msg.Type == "SHUTDOWN_ACK" {
				return
			}
		}
	}()
	select {
	case <-done:
	case <-time.After(500 * time.Millisecond):
	}
	if c.stdinPipe != nil {
		_ = c.stdinPipe.Close()
	}
	_ = c.cmd.Wait()
}

func workerStatusFromManifest(manifest WorkerManifest) WorkerStatus {
	return WorkerStatus{
		ID:             manifest.ID,
		Language:       manifest.Language,
		RuntimeVersion: manifest.Runtime,
		WorkerVersion:  manifest.WorkerVersion,
		Capabilities:   manifest.Capabilities,
		Status:         "available",
		SuccessRate:    1.0,
		FailureRate:    0.0,
		AverageRuntime: 0,
		LastHeartbeat:  time.Now().UTC().Format(time.RFC3339),
		Tier:           manifest.Tier,
	}
}

func listWorkers(root string) error {
	manifests, err := loadWorkerManifests(root)
	if err != nil {
		return err
	}
	var statuses []WorkerStatus
	for _, manifest := range manifests {
		statuses = append(statuses, workerStatusFromManifest(manifest))
	}
	return writeJSON(statuses)
}

func listCapabilities(root string) error {
	manifests, err := loadWorkerManifests(root)
	if err != nil {
		return err
	}
	type capabilityRecord struct {
		Capability string `json:"capability"`
		WorkerID   string `json:"workerId"`
		Language   string `json:"language"`
		Tier       string `json:"tier"`
	}
	var records []capabilityRecord
	for _, manifest := range manifests {
		for _, capability := range manifest.Capabilities {
			records = append(records, capabilityRecord{
				Capability: capability.Name,
				WorkerID:   manifest.ID,
				Language:   manifest.Language,
				Tier:       manifest.Tier,
			})
		}
	}
	return writeJSON(records)
}

func selectWorker(manifests []WorkerManifest, capability, language string) (WorkerManifest, []string, error) {
	candidates := make([]WorkerManifest, 0)
	for _, manifest := range manifests {
		if language != "" && manifest.Language != language {
			continue
		}
		for _, capabilityEntry := range manifest.Capabilities {
			if capabilityEntry.Name == capability {
				candidates = append(candidates, manifest)
				break
			}
		}
	}
	if len(candidates) == 0 {
		return WorkerManifest{}, nil, fmt.Errorf("no worker found for capability=%s language=%s", capability, language)
	}
	chosen := candidates[0]
	reason := []string{
		"capability matched",
		fmt.Sprintf("language=%s", chosen.Language),
		fmt.Sprintf("tier=%s", chosen.Tier),
		"local-first scheduler selected first compatible worker",
	}
	return chosen, reason, nil
}

func runJob(root string, request JobRequest) (RunResult, error) {
	manifests, err := loadWorkerManifests(root)
	if err != nil {
		return RunResult{}, err
	}
	manifest, reason, err := selectWorker(manifests, request.Capability, request.Language)
	if err != nil {
		return RunResult{}, err
	}
	conn, err := startWorker(root, manifest)
	if err != nil {
		return RunResult{}, err
	}
	defer conn.shutdown()

	jobID := fmt.Sprintf("job-%d", atomic.AddUint64(&jobCounter, 1))
	started := time.Now()
	if err := conn.send(Message{
		Type:       "JOB_START",
		Protocol:   "ofp/1",
		JobID:      jobID,
		Capability: request.Capability,
		Input:      request.Input,
	}); err != nil {
		return RunResult{}, err
	}

	messageCh := make(chan Message, 1)
	errorCh := make(chan error, 1)
	go func() {
		for {
			msg, err := conn.receive()
			if err != nil {
				errorCh <- err
				return
			}
			messageCh <- msg
			if msg.Type == "JOB_RESULT" || msg.Type == "JOB_ERROR" || msg.Type == "JOB_CANCELLED" {
				return
			}
		}
	}()

	var cancelTimer <-chan time.Time
	cancelSent := false
	if request.CancelAfterMs > 0 {
		cancelTimer = time.After(time.Duration(request.CancelAfterMs) * time.Millisecond)
	}

	for {
		select {
		case err := <-errorCh:
			return RunResult{}, err
		case <-cancelTimer:
			if !cancelSent {
				cancelSent = true
				if err := conn.send(Message{
					Type:     "JOB_CANCEL",
					Protocol: "ofp/1",
					JobID:    jobID,
					Reason:   "cancel timer exceeded",
				}); err != nil {
					return RunResult{}, err
				}
			}
			cancelTimer = nil
		case msg := <-messageCh:
			switch msg.Type {
			case "JOB_ACCEPTED", "JOB_PROGRESS", "JOB_LOG":
				continue
			case "JOB_ERROR":
				return RunResult{}, errors.New(msg.Error)
			case "JOB_CANCELLED":
				return RunResult{}, errors.New("job cancelled")
			case "JOB_RESULT":
				return RunResult{
					WorkerID:   manifest.ID,
					Language:   manifest.Language,
					Capability: request.Capability,
					Output:     msg.Output,
					Reason:     reason,
					ElapsedMs:  float64(time.Since(started).Milliseconds()),
				}, nil
			}
		}
	}
}

func loadJSON(path string, into any) error {
	raw, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, into)
}

func runPipeline(root, path, inputPath string) error {
	var pipeline PipelineDefinition
	if err := loadJSON(path, &pipeline); err != nil {
		return err
	}

	current := map[string]any{
		"inputPath": inputPath,
	}
	results := make([]RunResult, 0, len(pipeline.Steps))

	for _, step := range pipeline.Steps {
		result, err := runJob(root, JobRequest{
			Capability: step.Capability,
			Language:   step.Language,
			Input:      current,
		})
		if err != nil {
			return err
		}
		results = append(results, result)
		current = map[string]any{
			"previous": result.Output,
		}
	}

	pipelineResult := PipelineResult{
		Name:        pipeline.Name,
		Steps:       results,
		FinalOutput: results[len(results)-1].Output,
		Artifacts: map[string]any{
			"input": inputPath,
		},
	}
	return writeJSON(pipelineResult)
}

func writeJSON(v any) error {
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	return encoder.Encode(v)
}

func usage() {
	fmt.Println("omniforge coordinator (internal control plane)")
	fmt.Println("use the public CLI entry point instead: python omniforge.py")
}

func main() {
	root := rootDir()
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	switch os.Args[1] {
	case "workers":
		if err := listWorkers(root); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	case "capabilities":
		if err := listCapabilities(root); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	case "run-job":
		fs := flag.NewFlagSet("run-job", flag.ExitOnError)
		capability := fs.String("capability", "", "")
		language := fs.String("language", "", "")
		input := fs.String("input", "", "")
		cancelAfterMs := fs.Int("cancel-after-ms", 0, "")
		_ = fs.Parse(os.Args[2:])
		if *capability == "" || *input == "" {
			fmt.Fprintln(os.Stderr, "run-job requires --capability and --input")
			os.Exit(2)
		}
		var payload any
		if err := loadJSON(*input, &payload); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		result, err := runJob(root, JobRequest{
			Capability:    *capability,
			Language:      *language,
			Input:         payload,
			CancelAfterMs: *cancelAfterMs,
		})
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		_ = writeJSON(result)
	case "run-pipeline":
		fs := flag.NewFlagSet("run-pipeline", flag.ExitOnError)
		pipeline := fs.String("pipeline", "", "")
		input := fs.String("input", "", "")
		_ = fs.Parse(os.Args[2:])
		if *pipeline == "" || *input == "" {
			fmt.Fprintln(os.Stderr, "run-pipeline requires --pipeline and --input")
			os.Exit(2)
		}
		if err := runPipeline(root, *pipeline, *input); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	default:
		usage()
		os.Exit(2)
	}
}
