package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
)

type Message struct {
	Type         string         `json:"type"`
	Protocol     string         `json:"protocol,omitempty"`
	WorkerID     string         `json:"workerId,omitempty"`
	Language     string         `json:"language,omitempty"`
	Runtime      string         `json:"runtimeVersion,omitempty"`
	WorkerVersion string        `json:"workerVersion,omitempty"`
	Capabilities []map[string]any `json:"capabilities,omitempty"`
	JobID        string         `json:"jobId,omitempty"`
	Capability   string         `json:"capability,omitempty"`
	Input        map[string]any `json:"input,omitempty"`
	Output       any            `json:"output,omitempty"`
	Error        string         `json:"error,omitempty"`
	Progress     float64        `json:"progress,omitempty"`
	Status       string         `json:"status,omitempty"`
	Reason       string         `json:"reason,omitempty"`
	Severity     string         `json:"severity,omitempty"`
	LogMessage   string         `json:"message,omitempty"`
	Metadata     map[string]any `json:"metadata,omitempty"`
}

func send(msg Message) {
	raw, _ := json.Marshal(msg)
	fmt.Println(string(raw))
}

func asFloat(value any) float64 {
	switch typed := value.(type) {
	case float64:
		return typed
	case int:
		return float64(typed)
	default:
		return 0
	}
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		var message Message
		_ = json.Unmarshal(scanner.Bytes(), &message)
		switch message.Type {
		case "HELLO":
			send(Message{
				Type:          "WELCOME",
				Protocol:      "ofp/1",
				WorkerID:      "go-stats-01",
				Language:      "go",
				Runtime:       "1.25",
				WorkerVersion: "0.1.0",
				Status:        "ready",
			})
			send(Message{
				Type:          "REGISTER",
				Protocol:      "ofp/1",
				WorkerID:      "go-stats-01",
				Language:      "go",
				Runtime:       "1.25",
				WorkerVersion: "0.1.0",
				Capabilities: []map[string]any{
					{"name": "statistics.summary"},
				},
			})
		case "REGISTER_ACK":
			continue
		case "JOB_START":
			if message.Capability != "statistics.summary" {
				send(Message{Type: "JOB_ERROR", JobID: message.JobID, Error: "unsupported capability"})
				continue
			}
			send(Message{Type: "JOB_ACCEPTED", JobID: message.JobID, Status: "running"})
			send(Message{Type: "JOB_LOG", JobID: message.JobID, Severity: "info", LogMessage: "starting statistics.summary"})
			prev := message.Input["previous"].(map[string]any)
			rows := prev["rows"].([]any)
			total := 0.0
			active := 0
			for _, row := range rows {
				typed := row.(map[string]any)
				total += asFloat(typed["amount"])
				if typed["active"] == true {
					active++
				}
			}
			send(Message{Type: "JOB_PROGRESS", JobID: message.JobID, Progress: 0.9, Metadata: map[string]any{"stage": "statistics"}})
			send(Message{
				Type:  "JOB_RESULT",
				JobID: message.JobID,
				Output: map[string]any{
					"rows": rows,
					"valid": prev["valid"],
					"counts": prev["counts"],
					"summary": map[string]any{
						"rowCount": len(rows),
						"activeCount": active,
						"totalAmount": total,
						"averageAmount": total / float64(len(rows)),
					},
				},
			})
		case "JOB_CANCEL":
			send(Message{Type: "JOB_CANCELLED", JobID: message.JobID, Status: "cancelled"})
		case "SHUTDOWN":
			send(Message{Type: "SHUTDOWN_ACK", WorkerID: "go-stats-01", Status: "stopped"})
			return
		}
	}
}
