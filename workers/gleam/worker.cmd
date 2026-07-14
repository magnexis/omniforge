@echo off
cd /d "%~dp0"
set PATH=C:\Program Files\Erlang OTP\bin;%PATH%
if not exist build\dev\erlang\omniforge_gleam_worker\ebin mkdir build\dev\erlang\omniforge_gleam_worker\ebin
erlc -o build\dev\erlang\omniforge_gleam_worker\ebin src\worker_io.erl
if errorlevel 1 exit /b 1
erl -noshell -pa build\dev\erlang\gleam_stdlib\ebin -pa build\dev\erlang\omniforge_gleam_worker\ebin -eval "application:ensure_all_started(omniforge_gleam_worker), worker:main()."
