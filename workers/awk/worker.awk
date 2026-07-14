{
  if ($0 ~ /"type":"HELLO"/) {
    print "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"awk-tokenize-01\",\"language\":\"awk\",\"runtimeVersion\":\"gawk\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"text.tokenize\"}]}"
    fflush()
  } else if ($0 ~ /"type":"JOB_START"/) {
    if ($0 !~ /"capability":"text.tokenize"/) {
      print "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}"
      fflush()
      next
    }
    match($0, /"jobId":"[^"]+"/)
    job = substr($0, RSTART + 9, RLENGTH - 10)
    match($0, /"text":"[^"]+"/)
    text = substr($0, RSTART + 8, RLENGTH - 9)
    count = split(text, parts, /[[:space:]]+/)
    printf "{\"type\":\"JOB_RESULT\",\"jobId\":\"%s\",\"output\":{\"tokens\":%d}}\n", job, count
    fflush()
  } else if ($0 ~ /"type":"SHUTDOWN"/) {
    exit
  }
}
