#!/usr/bin/env bash
set -euo pipefail

while IFS= read -r line; do
  if [[ "$line" == *'"type":"HELLO"'* ]]; then
    echo '{"type":"REGISTER","protocol":"ofp/1","workerId":"bash-uppercase-01","language":"bash","runtimeVersion":"git-bash","workerVersion":"0.1.0","capabilities":[{"name":"text.uppercase"}]}'
  elif [[ "$line" == *'"type":"JOB_START"'* ]]; then
    if [[ "$line" != *'"capability":"text.uppercase"'* ]]; then
      echo '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
      continue
    fi
    job_id=""
    text=""
    if [[ $line =~ \"jobId\":\"([^\"]*)\" ]]; then
      job_id="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ \"text\":\"([^\"]*)\" ]]; then
      text="${BASH_REMATCH[1]}"
    fi
    upper="${text^^}"
    printf '{"type":"JOB_RESULT","jobId":"%s","output":{"uppercase":"%s"}}\n' "$job_id" "$upper"
  elif [[ "$line" == *'"type":"SHUTDOWN"'* ]]; then
    break
  fi
done
