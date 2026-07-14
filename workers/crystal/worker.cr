def send(message : String)
  STDOUT.puts(message)
  STDOUT.flush
end

def extract(line : String, marker : String) : String
  start = line.index(marker)
  return "" unless start
  rest = line[(start + marker.size)..]
  stop = rest.index('"')
  return "" unless stop
  rest[0, stop]
end

STDIN.each_line do |line|
  line = line.rstrip
  if line.includes?("\"type\":\"HELLO\"")
    send(%({"type":"REGISTER","protocol":"ofp/1","workerId":"crystal-length-01","language":"crystal","runtimeVersion":"1.20.3","workerVersion":"0.1.0","capabilities":[{"name":"text.length-cr"}]}))
  elsif line.includes?("\"type\":\"JOB_START\"")
    if !line.includes?("\"capability\":\"text.length-cr\"")
      send(%({"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}))
    else
      job_id = extract(line, "\"jobId\":\"")
      job_id = "job-unknown" if job_id.empty?
      text = extract(line, "\"text\":\"")
      send(%({"type":"JOB_RESULT","jobId":"#{job_id}","output":{"length":#{text.size}}}))
    end
  elsif line.includes?("\"type\":\"SHUTDOWN\"")
    exit(0)
  end
end
