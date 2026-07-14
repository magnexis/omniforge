import argparse
import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
LANGUAGES_DIR = ROOT / "languages"
TEMPLATE_METADATA = ROOT / "templates" / "language-metadata.json"
TEMPLATE_README = ROOT / "templates" / "language-README.md"
FORGE_MESSAGE = "hello-forge"
REQUIRED_LANGUAGE_DIRS = [
    "toolchain",
    "examples",
    "algorithms",
    "web",
    "networking",
    "filesystem",
    "json",
    "xml",
    "database",
    "threads",
    "benchmarks",
    "tests",
    "compiler",
    "documentation",
    "history",
]
COMMAND_ALIASES = {
    "lua": r"C:\Users\matth\AppData\Local\Programs\Lua\bin\lua.exe",
    "scala": r"C:\Program Files (x86)\scala\bin\scala.bat",
    "scalac": r"C:\Program Files (x86)\scala\bin\scalac.bat",
}

SEED_LANGUAGES: list[dict[str, Any]] = [
    {
        "slug": "c",
        "name": "C",
        "creator": "Dennis Ritchie",
        "year": 1972,
        "typing": "static, weak",
        "memory_model": "manual memory management",
        "garbage_collected": False,
        "compiled": True,
        "interpreted": False,
        "license": "ISO standard",
        "package_manager": "none",
        "compiler": "clang",
        "runtime": "native",
        "official_site": "https://www.iso.org/standard/82075.html",
        "documentation": "https://en.cppreference.com/w/c",
        "github": "https://github.com/llvm/llvm-project",
        "paradigm": ["procedural", "systems"],
        "inspired_by": ["B"],
        "inspired": ["C++", "Objective-C", "C#"],
        "status": "active",
        "feature_flags": {"coroutines": False, "ffi": True, "macros": True, "generics": False},
        "ecosystem": {"package_count": 0, "primary_domains": ["systems", "embedded"], "notable_companies": []},
        "detector": "clang",
        "source_file": "main.c",
        "artifact": "hello.exe",
        "build": ["clang", "examples/hello-world/main.c", "-o", "examples/hello-world/hello.exe"],
        "run": ["examples/hello-world/hello.exe"],
        "source": "#include <stdio.h>\n\nint main(void) {\n    puts(\"{\\\"language\\\":\\\"c\\\",\\\"message\\\":\\\"hello-forge\\\"}\");\n    return 0;\n}\n",
    },
    {
        "slug": "cpp",
        "name": "C++",
        "creator": "Bjarne Stroustrup",
        "year": 1985,
        "typing": "static, strong",
        "memory_model": "manual and RAII",
        "garbage_collected": False,
        "compiled": True,
        "interpreted": False,
        "license": "ISO standard",
        "package_manager": "vcpkg",
        "compiler": "clang++",
        "runtime": "native",
        "official_site": "https://isocpp.org/",
        "documentation": "https://en.cppreference.com/w/",
        "github": "https://github.com/llvm/llvm-project",
        "paradigm": ["systems", "object-oriented", "generic"],
        "inspired_by": ["C", "Simula"],
        "inspired": ["Java", "Rust", "C#"],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": True, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["systems", "games", "finance"], "notable_companies": []},
        "detector": "clang++",
        "source_file": "main.cpp",
        "artifact": "hello.exe",
        "build": ["clang++", "examples/hello-world/main.cpp", "-std=c++20", "-o", "examples/hello-world/hello.exe"],
        "run": ["examples/hello-world/hello.exe"],
        "source": "#include <iostream>\n\nint main() {\n    std::cout << \"{\\\"language\\\":\\\"cpp\\\",\\\"message\\\":\\\"hello-forge\\\"}\" << std::endl;\n    return 0;\n}\n",
    },
    {
        "slug": "csharp",
        "name": "C#",
        "creator": "Anders Hejlsberg",
        "year": 2000,
        "typing": "static, strong",
        "memory_model": "managed runtime",
        "garbage_collected": True,
        "compiled": True,
        "interpreted": False,
        "license": "MIT",
        "package_manager": "NuGet",
        "compiler": "dotnet",
        "runtime": ".NET",
        "official_site": "https://dotnet.microsoft.com/en-us/languages/csharp",
        "documentation": "https://learn.microsoft.com/dotnet/csharp/",
        "github": "https://github.com/dotnet/csharplang",
        "paradigm": ["object-oriented", "functional", "multi-paradigm"],
        "inspired_by": ["C++", "Java", "Delphi"],
        "inspired": [],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["enterprise", "web", "desktop"], "notable_companies": []},
        "detector": "dotnet",
        "source_file": "Program.cs",
        "project_file": "HelloForge.csproj",
        "build": ["dotnet", "build", "examples/hello-world/HelloForge.csproj", "-nologo"],
        "run": ["examples/hello-world/bin/Debug/net9.0/HelloForge.exe"],
        "source": "using System;\n\nConsole.WriteLine(\"{\\\"language\\\":\\\"csharp\\\",\\\"message\\\":\\\"hello-forge\\\"}\");\n",
        "project": "<Project Sdk=\"Microsoft.NET.Sdk\">\n  <PropertyGroup>\n    <OutputType>Exe</OutputType>\n    <TargetFramework>net9.0</TargetFramework>\n    <ImplicitUsings>enable</ImplicitUsings>\n    <Nullable>enable</Nullable>\n  </PropertyGroup>\n</Project>\n",
    },
    {
        "slug": "dart",
        "name": "Dart",
        "creator": "Lars Bak and Kasper Lund",
        "year": 2011,
        "typing": "static, strong",
        "memory_model": "garbage collected",
        "garbage_collected": True,
        "compiled": True,
        "interpreted": True,
        "license": "BSD-3-Clause",
        "package_manager": "pub",
        "compiler": "dart",
        "runtime": "Dart VM",
        "official_site": "https://dart.dev/",
        "documentation": "https://dart.dev/guides",
        "github": "https://github.com/dart-lang/sdk",
        "paradigm": ["object-oriented", "client", "server"],
        "inspired_by": ["Java", "JavaScript", "Erlang"],
        "inspired": [],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["web", "mobile", "tooling"], "notable_companies": []},
        "detector": "dart",
        "source_file": "main.dart",
        "build": [],
        "run": ["dart", "examples/hello-world/main.dart"],
        "source": "void main() {\n  print('{\"language\":\"dart\",\"message\":\"hello-forge\"}');\n}\n",
    },
    {
        "slug": "fsharp",
        "name": "F#",
        "creator": "Don Syme",
        "year": 2005,
        "typing": "static, strong, inferred",
        "memory_model": "managed runtime",
        "garbage_collected": True,
        "compiled": True,
        "interpreted": False,
        "license": "Apache-2.0",
        "package_manager": "NuGet",
        "compiler": "dotnet",
        "runtime": ".NET",
        "official_site": "https://fsharp.org/",
        "documentation": "https://learn.microsoft.com/dotnet/fsharp/",
        "github": "https://github.com/dotnet/fsharp",
        "paradigm": ["functional", "multi-paradigm"],
        "inspired_by": ["OCaml", "ML", "C#"],
        "inspired": [],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["data", "finance", "tooling"], "notable_companies": []},
        "detector": "dotnet",
        "source_file": "Program.fs",
        "project_file": "HelloForge.fsproj",
        "build": ["dotnet", "build", "examples/hello-world/HelloForge.fsproj", "-nologo"],
        "run": ["examples/hello-world/bin/Debug/net9.0/HelloForge.exe"],
        "source": "printfn \"{\\\"language\\\":\\\"fsharp\\\",\\\"message\\\":\\\"hello-forge\\\"}\"\n",
        "project": "<Project Sdk=\"Microsoft.NET.Sdk\">\n  <PropertyGroup>\n    <OutputType>Exe</OutputType>\n    <TargetFramework>net9.0</TargetFramework>\n  </PropertyGroup>\n  <ItemGroup>\n    <Compile Include=\"Program.fs\" />\n  </ItemGroup>\n</Project>\n",
    },
    {
        "slug": "go",
        "name": "Go",
        "creator": "Robert Griesemer, Rob Pike, Ken Thompson",
        "year": 2009,
        "typing": "static, strong, inferred",
        "memory_model": "garbage collected",
        "garbage_collected": True,
        "compiled": True,
        "interpreted": False,
        "license": "BSD-3-Clause",
        "package_manager": "go modules",
        "compiler": "go",
        "runtime": "native",
        "official_site": "https://go.dev/",
        "documentation": "https://go.dev/doc/",
        "github": "https://github.com/golang/go",
        "paradigm": ["concurrent", "systems", "procedural"],
        "inspired_by": ["C", "Pascal", "Modula"],
        "inspired": [],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["cloud", "cli", "backend"], "notable_companies": []},
        "detector": "go",
        "source_file": "main.go",
        "build": ["go", "build", "-o", "examples/hello-world/hello.exe", "examples/hello-world/main.go"],
        "run": ["examples/hello-world/hello.exe"],
        "source": "package main\n\nimport \"fmt\"\n\nfunc main() {\n    fmt.Println(\"{\\\"language\\\":\\\"go\\\",\\\"message\\\":\\\"hello-forge\\\"}\")\n}\n",
        "module": "module polyglotforge/languages/go/examples/hello-world\n\ngo 1.25.0\n",
    },
    {
        "slug": "java",
        "name": "Java",
        "creator": "James Gosling",
        "year": 1995,
        "typing": "static, strong",
        "memory_model": "managed runtime",
        "garbage_collected": True,
        "compiled": True,
        "interpreted": False,
        "license": "GPL-2.0-with-classpath-exception",
        "package_manager": "Maven",
        "compiler": "javac",
        "runtime": "JVM",
        "official_site": "https://www.java.com/",
        "documentation": "https://docs.oracle.com/en/java/",
        "github": "https://github.com/openjdk/jdk",
        "paradigm": ["object-oriented", "class-based"],
        "inspired_by": ["C++", "Smalltalk"],
        "inspired": ["Kotlin", "C#"],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["enterprise", "backend", "android"], "notable_companies": []},
        "detector": "javac",
        "source_file": "Main.java",
        "build": ["javac", "examples/hello-world/Main.java"],
        "run": ["java", "-cp", "examples/hello-world", "Main"],
        "source": "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"{\\\"language\\\":\\\"java\\\",\\\"message\\\":\\\"hello-forge\\\"}\");\n    }\n}\n",
    },
    {
        "slug": "javascript",
        "name": "JavaScript",
        "creator": "Brendan Eich",
        "year": 1995,
        "typing": "dynamic, weak",
        "memory_model": "garbage collected",
        "garbage_collected": True,
        "compiled": False,
        "interpreted": True,
        "license": "ECMA standard",
        "package_manager": "npm",
        "compiler": "node",
        "runtime": "Node.js",
        "official_site": "https://developer.mozilla.org/docs/Web/JavaScript",
        "documentation": "https://developer.mozilla.org/docs/Web/JavaScript",
        "github": "https://github.com/nodejs/node",
        "paradigm": ["event-driven", "functional", "prototype-based"],
        "inspired_by": ["Scheme", "Self", "Java"],
        "inspired": ["TypeScript"],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": False},
        "ecosystem": {"package_count": 0, "primary_domains": ["web", "tooling", "backend"], "notable_companies": []},
        "detector": "node",
        "source_file": "main.js",
        "build": [],
        "run": ["node", "examples/hello-world/main.js"],
        "source": "console.log('{\"language\":\"javascript\",\"message\":\"hello-forge\"}');\n",
    },
    {
        "slug": "lua",
        "name": "Lua",
        "creator": "Roberto Ierusalimschy, Luiz Henrique de Figueiredo, Waldemar Celes",
        "year": 1993,
        "typing": "dynamic",
        "memory_model": "garbage collected",
        "garbage_collected": True,
        "compiled": False,
        "interpreted": True,
        "license": "MIT",
        "package_manager": "LuaRocks",
        "compiler": "lua",
        "runtime": "Lua VM",
        "official_site": "https://www.lua.org/",
        "documentation": "https://www.lua.org/docs.html",
        "github": "https://github.com/lua/lua",
        "paradigm": ["scripting", "embeddable"],
        "inspired_by": ["Scheme", "Modula", "C"],
        "inspired": ["Luau", "Terra"],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": False, "macros": False, "generics": False},
        "ecosystem": {"package_count": 0, "primary_domains": ["embedded", "games", "scripting"], "notable_companies": []},
        "detector": "lua",
        "source_file": "main.lua",
        "build": [],
        "run": ["lua", "examples/hello-world/main.lua"],
        "source": "print('{\"language\":\"lua\",\"message\":\"hello-forge\"}')\n",
    },
    {
        "slug": "python",
        "name": "Python",
        "creator": "Guido van Rossum",
        "year": 1991,
        "typing": "dynamic, strong",
        "memory_model": "reference counting with GC",
        "garbage_collected": True,
        "compiled": False,
        "interpreted": True,
        "license": "PSF-2.0",
        "package_manager": "pip",
        "compiler": "python",
        "runtime": "CPython",
        "official_site": "https://www.python.org/",
        "documentation": "https://docs.python.org/3/",
        "github": "https://github.com/python/cpython",
        "paradigm": ["scripting", "object-oriented", "functional"],
        "inspired_by": ["ABC", "Modula-3", "C"],
        "inspired": [],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["automation", "data", "web"], "notable_companies": []},
        "detector": "python",
        "source_file": "main.py",
        "build": [],
        "run": ["python", "examples/hello-world/main.py"],
        "source": "print('{\"language\":\"python\",\"message\":\"hello-forge\"}')\n",
    },
    {
        "slug": "ruby",
        "name": "Ruby",
        "creator": "Yukihiro Matsumoto",
        "year": 1995,
        "typing": "dynamic, strong",
        "memory_model": "garbage collected",
        "garbage_collected": True,
        "compiled": False,
        "interpreted": True,
        "license": "Ruby or BSD-2-Clause",
        "package_manager": "RubyGems",
        "compiler": "ruby",
        "runtime": "MRI",
        "official_site": "https://www.ruby-lang.org/",
        "documentation": "https://www.ruby-lang.org/en/documentation/",
        "github": "https://github.com/ruby/ruby",
        "paradigm": ["object-oriented", "scripting"],
        "inspired_by": ["Perl", "Smalltalk", "Lisp"],
        "inspired": ["Crystal"],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": False, "generics": False},
        "ecosystem": {"package_count": 0, "primary_domains": ["web", "automation"], "notable_companies": []},
        "detector": "ruby",
        "source_file": "main.rb",
        "build": [],
        "run": ["ruby", "examples/hello-world/main.rb"],
        "source": "puts '{\"language\":\"ruby\",\"message\":\"hello-forge\"}'\n",
    },
    {
        "slug": "rust",
        "name": "Rust",
        "creator": "Graydon Hoare",
        "year": 2010,
        "typing": "static, strong, inferred",
        "memory_model": "ownership and borrowing",
        "garbage_collected": False,
        "compiled": True,
        "interpreted": False,
        "license": "MIT OR Apache-2.0",
        "package_manager": "Cargo",
        "compiler": "cargo",
        "runtime": "native",
        "official_site": "https://www.rust-lang.org/",
        "documentation": "https://doc.rust-lang.org/",
        "github": "https://github.com/rust-lang/rust",
        "paradigm": ["systems", "functional", "concurrent", "multi-paradigm"],
        "inspired_by": ["C++", "ML", "Haskell", "Ruby"],
        "inspired": [],
        "status": "active",
        "feature_flags": {"coroutines": False, "ffi": True, "macros": True, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["systems", "cli", "web", "embedded"], "notable_companies": []},
        "detector": "cargo",
        "source_file": "src/main.rs",
        "build": ["cargo", "build", "--manifest-path", "examples/hello-world/Cargo.toml"],
        "run": ["cargo", "run", "--quiet", "--manifest-path", "examples/hello-world/Cargo.toml"],
        "source": "fn main() {\n    println!(\"{{\\\"language\\\":\\\"rust\\\",\\\"message\\\":\\\"hello-forge\\\"}}\");\n}\n",
        "manifest": "[package]\nname = \"hello-forge\"\nversion = \"0.1.0\"\nedition = \"2024\"\n\n[dependencies]\n",
    },
    {
        "slug": "scala",
        "name": "Scala",
        "creator": "Martin Odersky",
        "year": 2004,
        "typing": "static, strong, inferred",
        "memory_model": "managed runtime",
        "garbage_collected": True,
        "compiled": True,
        "interpreted": False,
        "license": "Apache-2.0",
        "package_manager": "sbt",
        "compiler": "scalac",
        "runtime": "JVM",
        "official_site": "https://www.scala-lang.org/",
        "documentation": "https://docs.scala-lang.org/",
        "github": "https://github.com/scala/scala",
        "paradigm": ["functional", "object-oriented", "jvm"],
        "inspired_by": ["Java", "Haskell", "ML"],
        "inspired": ["Kotlin"],
        "status": "active",
        "feature_flags": {"coroutines": False, "ffi": True, "macros": True, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["backend", "data", "distributed-systems"], "notable_companies": []},
        "detector": "scalac",
        "source_file": "Main.scala",
        "build": [],
        "run": ["scala", "examples/hello-world/Main.scala"],
        "source": "println(\"{\\\"language\\\":\\\"scala\\\",\\\"message\\\":\\\"hello-forge\\\"}\")\n",
    },
    {
        "slug": "zig",
        "name": "Zig",
        "creator": "Andrew Kelley",
        "year": 2016,
        "typing": "static, strong",
        "memory_model": "manual memory management",
        "garbage_collected": False,
        "compiled": True,
        "interpreted": False,
        "license": "MIT",
        "package_manager": "zig build",
        "compiler": "zig",
        "runtime": "native",
        "official_site": "https://ziglang.org/",
        "documentation": "https://ziglang.org/documentation/master/",
        "github": "https://github.com/ziglang/zig",
        "paradigm": ["systems", "procedural"],
        "inspired_by": ["C", "Rust"],
        "inspired": [],
        "status": "active",
        "feature_flags": {"coroutines": True, "ffi": True, "macros": True, "generics": True},
        "ecosystem": {"package_count": 0, "primary_domains": ["systems", "tooling"], "notable_companies": []},
        "detector": "zig",
        "source_file": "main.zig",
        "build": ["zig", "build-exe", "examples/hello-world/main.zig", "-femit-bin=examples/hello-world/hello.exe"],
        "run": ["examples/hello-world/hello.exe"],
        "source": "const std = @import(\"std\");\n\npub fn main() !void {\n    const stdout = std.io.getStdOut().writer();\n    try stdout.print(\"{{\\\"language\\\":\\\"zig\\\",\\\"message\\\":\\\"hello-forge\\\"}}\\n\", .{});\n}\n",
    },
]


def iter_language_dirs() -> list[Path]:
    if not LANGUAGES_DIR.exists():
        return []
    return sorted(path for path in LANGUAGES_DIR.iterdir() if path.is_dir())


def command_exists(name: str) -> bool:
    if shutil.which(name) is not None:
        return True
    alias = COMMAND_ALIASES.get(name)
    if not alias:
        return False
    try:
        return Path(alias).exists()
    except PermissionError:
        return False


def resolve_command(name: str, cwd: Path) -> str:
    executable = cwd / name
    if executable.exists():
        return str(executable)
    if shutil.which(name) is not None:
        return name
    alias = COMMAND_ALIASES.get(name)
    if alias:
        try:
            if Path(alias).exists():
                return alias
        except PermissionError:
            pass
    return name


def write_text_if_changed(path: Path, content: str) -> None:
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def build_metadata(seed: dict[str, Any]) -> dict[str, Any]:
    metadata = json.loads(TEMPLATE_METADATA.read_text(encoding="utf-8"))
    for key, value in seed.items():
        if key in {"detector", "source_file", "source", "build", "run", "artifact", "project", "project_file", "module", "manifest"}:
            continue
        metadata[key] = value
    return metadata


def scaffold_language(slug: str, name: str) -> int:
    language_dir = LANGUAGES_DIR / slug
    language_dir.mkdir(parents=True, exist_ok=True)

    metadata = json.loads(TEMPLATE_METADATA.read_text(encoding="utf-8"))
    metadata["slug"] = slug
    metadata["name"] = name
    metadata_path = language_dir / "metadata.json"
    if not metadata_path.exists():
        metadata_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")

    readme = TEMPLATE_README.read_text(encoding="utf-8")
    readme = readme.replace("{{NAME}}", name).replace("{{SLUG}}", slug)
    readme_path = language_dir / "README.md"
    if not readme_path.exists():
        readme_path.write_text(readme + "\n", encoding="utf-8")

    for dirname in REQUIRED_LANGUAGE_DIRS:
        (language_dir / dirname).mkdir(exist_ok=True)

    print(f"Scaffolded language entry: {slug}")
    return 0


def seed_language(seed: dict[str, Any]) -> None:
    scaffold_language(seed["slug"], seed["name"])
    language_dir = LANGUAGES_DIR / seed["slug"]

    metadata = build_metadata(seed)
    write_text_if_changed(language_dir / "metadata.json", json.dumps(metadata, indent=2) + "\n")

    readme = TEMPLATE_README.read_text(encoding="utf-8")
    readme = readme.replace("{{NAME}}", seed["name"]).replace("{{SLUG}}", seed["slug"])
    readme += "\n## Forge Hello World\n\n"
    readme += "This entry includes a runnable `examples/hello-world/` program that emits the shared Forge JSON payload.\n"
    write_text_if_changed(language_dir / "README.md", readme + "\n")

    hello_dir = language_dir / "examples" / "hello-world"
    write_text_if_changed(hello_dir / seed["source_file"], seed["source"])

    if "project_file" in seed and "project" in seed:
        write_text_if_changed(hello_dir / seed["project_file"], seed["project"])
    if "module" in seed:
        write_text_if_changed(hello_dir / "go.mod", seed["module"])
    if "manifest" in seed:
        write_text_if_changed(hello_dir / "Cargo.toml", seed["manifest"])

    toolchain_manifest = {
        "detector": seed["detector"],
        "build": seed["build"],
        "run": seed["run"],
        "expected": {"language": seed["slug"], "message": FORGE_MESSAGE},
    }
    write_text_if_changed(
        language_dir / "toolchain" / "manifest.json",
        json.dumps(toolchain_manifest, indent=2) + "\n",
    )


def seed_installed() -> int:
    seeded = []
    skipped = []
    for seed in SEED_LANGUAGES:
        if command_exists(seed["detector"]):
            seed_language(seed)
            seeded.append(seed["slug"])
        else:
            skipped.append(seed["slug"])

    print(f"Seeded languages: {len(seeded)}")
    for slug in seeded:
        print(f"- {slug}")
    if skipped:
        print("Skipped missing toolchains:")
        for slug in skipped:
            print(f"- {slug}")
    return 0


def run_manifest(language_dir: Path) -> dict[str, Any]:
    manifest_path = language_dir / "toolchain" / "manifest.json"
    if not manifest_path.exists():
        raise FileNotFoundError(f"Missing manifest for {language_dir.name}")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def execute_command(command: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    resolved = list(command)
    resolved[0] = resolve_command(command[0], cwd)
    env = dict(os.environ)
    cache_root = ROOT / ".cache"
    dotnet_home = cache_root / "dotnet"
    appdata = cache_root / "appdata"
    nuget_dir = appdata / "NuGet"
    env["DOTNET_CLI_HOME"] = str(dotnet_home)
    env["DOTNET_SKIP_FIRST_TIME_EXPERIENCE"] = "1"
    env["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1"
    env["APPDATA"] = str(appdata)
    env["NUGET_PACKAGES"] = str(cache_root / "nuget-packages")
    dotnet_home.mkdir(parents=True, exist_ok=True)
    nuget_dir.mkdir(parents=True, exist_ok=True)
    write_text_if_changed(nuget_dir / "NuGet.Config", "<configuration />\n")
    return subprocess.run(resolved, cwd=cwd, capture_output=True, text=True, check=False, env=env)


def run_examples() -> int:
    failures = []
    successes = []
    for language_dir in iter_language_dirs():
        manifest_path = language_dir / "toolchain" / "manifest.json"
        if not manifest_path.exists():
            continue

        manifest = run_manifest(language_dir)
        detector = manifest["detector"]
        if not command_exists(detector):
            failures.append(f"{language_dir.name}: missing detector {detector}")
            continue

        if manifest["build"]:
            build = execute_command(manifest["build"], language_dir)
            if build.returncode != 0:
                failures.append(f"{language_dir.name}: build failed\n{build.stderr.strip()}")
                continue

        run = execute_command(manifest["run"], language_dir)
        if run.returncode != 0:
            failures.append(f"{language_dir.name}: run failed\n{run.stderr.strip()}")
            continue

        output = run.stdout.strip()
        try:
            payload = json.loads(output)
        except json.JSONDecodeError as exc:
            failures.append(f"{language_dir.name}: invalid JSON output ({exc})")
            continue

        expected = manifest["expected"]
        if payload != expected:
            failures.append(f"{language_dir.name}: output mismatch {payload!r} != {expected!r}")
            continue

        successes.append(language_dir.name)

    print(f"Successful runs: {len(successes)}")
    for slug in successes:
        print(f"- {slug}")

    if failures:
        print("Failures:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    return 0


def validate() -> int:
    issues = []
    for language_dir in iter_language_dirs():
        metadata_path = language_dir / "metadata.json"
        readme_path = language_dir / "README.md"
        if not metadata_path.exists():
            issues.append(f"{language_dir.name}: missing metadata.json")
        if not readme_path.exists():
            issues.append(f"{language_dir.name}: missing README.md")
        for dirname in REQUIRED_LANGUAGE_DIRS:
            expected = language_dir / dirname
            if not expected.exists():
                issues.append(f"{language_dir.name}: missing directory {dirname}")
        manifest_path = language_dir / "toolchain" / "manifest.json"
        if manifest_path.exists():
            try:
                manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                issues.append(f"{language_dir.name}: invalid toolchain manifest ({exc})")
                continue
            for key in ("detector", "build", "run", "expected"):
                if key not in manifest:
                    issues.append(f"{language_dir.name}: toolchain manifest missing {key}")

    if issues:
        print("Validation failed:")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print("Validation passed.")
    return 0


def report() -> int:
    languages = list(iter_language_dirs())
    print(f"Tracked languages: {len(languages)}")
    for language_dir in languages:
        manifest_path = language_dir / "toolchain" / "manifest.json"
        runtime = "unmanaged"
        if manifest_path.exists():
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            runtime = manifest["detector"]
        print(f"- {language_dir.name} ({runtime})")
    return 0


def doctor() -> int:
    print("Detected toolchains:")
    for seed in SEED_LANGUAGES:
        status = "available" if command_exists(seed["detector"]) else "missing"
        print(f"- {seed['slug']}: {seed['detector']} -> {status}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Polyglot Forge project utility.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("validate", help="Validate language directory structure.")
    subparsers.add_parser("report", help="Print a simple catalog summary.")
    subparsers.add_parser("doctor", help="Inspect available local toolchains.")
    subparsers.add_parser("seed-installed", help="Scaffold all supported languages available on this machine.")
    subparsers.add_parser("run-examples", help="Build and run shared hello-world examples.")

    scaffold = subparsers.add_parser("scaffold-language", help="Create a new language entry.")
    scaffold.add_argument("--slug", required=True)
    scaffold.add_argument("--name", required=True)

    args = parser.parse_args()

    if args.command == "validate":
        return validate()
    if args.command == "report":
        return report()
    if args.command == "doctor":
        return doctor()
    if args.command == "seed-installed":
        return seed_installed()
    if args.command == "run-examples":
        return run_examples()
    if args.command == "scaffold-language":
        return scaffold_language(args.slug, args.name)
    parser.error(f"Unsupported command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
