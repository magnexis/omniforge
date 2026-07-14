local function send(message)
  io.write(message .. "\n")
  io.flush()
end

for line in io.lines() do
  if line:find('"type":"HELLO"') then
    send('{"type":"WELCOME","protocol":"ofp/1","workerId":"lua-template-01","language":"lua","runtimeVersion":"5.4","workerVersion":"0.1.0","status":"ready"}')
    send('{"type":"REGISTER","protocol":"ofp/1","workerId":"lua-template-01","language":"lua","runtimeVersion":"5.4","workerVersion":"0.1.0","capabilities":[{"name":"text.template"}]}')
  elseif line:find('"type":"REGISTER_ACK"') then
    -- no-op
  elseif line:find('"type":"JOB_START"') then
    if not line:find('"capability":"text.template"') then
      send('{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}')
    else
      local jobId = line:match('"jobId":"([^"]+)"') or "job-unknown"
      local name = line:match('"name":"([^"]+)"') or "friend"
      local capability = line:match('"capability":"([^"]+)"') or "text.template"
      send(string.format('{"type":"JOB_ACCEPTED","jobId":"%s","status":"running"}', jobId))
      send(string.format('{"type":"JOB_LOG","jobId":"%s","severity":"info","message":"starting text.template"}', jobId))
      send(string.format('{"type":"JOB_RESULT","jobId":"%s","output":{"rendered":"Hello %s from %s"}}', jobId, name, capability))
    end
  elseif line:find('"type":"JOB_CANCEL"') then
    local jobId = line:match('"jobId":"([^"]+)"') or "job-unknown"
    send(string.format('{"type":"JOB_CANCELLED","jobId":"%s","status":"cancelled"}', jobId))
  elseif line:find('"type":"SHUTDOWN"') then
    send('{"type":"SHUTDOWN_ACK","workerId":"lua-template-01","status":"stopped"}')
    break
  end
end
