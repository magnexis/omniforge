#!/bin/sh
while IFS= read -r line; do
  case "$line" in
    *'"type":"HELLO"'*)
      echo '{"type":"REGISTER","protocol":"ofp/1","workerId":"sh-lowercase-01","language":"sh","runtimeVersion":"git-sh","workerVersion":"0.1.0","capabilities":[{"name":"text.lowercase"}]}'
      ;;
    *'"type":"JOB_START"'*)
      case "$line" in
        *'"capability":"text.lowercase"'*)
          job_id=$(printf '%s' "$line" | awk 'match($0, /"jobId":"[^"]+"/) { print substr($0, RSTART+9, RLENGTH-10) }')
          text=$(printf '%s' "$line" | awk 'match($0, /"text":"[^"]+"/) { print substr($0, RSTART+8, RLENGTH-9) }')
          lower=$(printf '%s' "$text" | awk '{ print tolower($0) }')
          printf '{"type":"JOB_RESULT","jobId":"%s","output":{"lowercase":"%s"}}\n' "$job_id" "$lower"
          ;;
        *)
          echo '{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}'
          ;;
      esac
      ;;
    *'"type":"SHUTDOWN"'*)
      break
      ;;
  esac
done
