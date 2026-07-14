import std/[strutils]

proc send(msg: string) =
  stdout.writeLine(msg)
  stdout.flushFile()

proc extract(line, key: string): string =
  let marker = "\"" & key & "\":\""
  let start = line.find(marker)
  if start < 0: return ""
  let s = start + marker.len
  let tail = line[s .. ^1]
  let stop = tail.find('"')
  if stop < 0: return ""
  tail[0 ..< stop]

when isMainModule:
  while true:
    if stdin.endOfFile: break
    let line = stdin.readLine()
    if line.contains("\"type\":\"HELLO\""):
      send("{\"type\":\"WELCOME\",\"protocol\":\"ofp/1\",\"workerId\":\"nim-palindrome-01\",\"language\":\"nim\",\"runtimeVersion\":\"2.0.8\",\"workerVersion\":\"0.1.0\",\"status\":\"ready\"}")
      send("{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"nim-palindrome-01\",\"language\":\"nim\",\"runtimeVersion\":\"2.0.8\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"text.palindrome\"}]}")
    elif line.contains("\"type\":\"REGISTER_ACK\""):
      discard
    elif line.contains("\"type\":\"JOB_START\""):
      if not line.contains("\"capability\":\"text.palindrome\""):
        send("{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}")
      else:
        let jobId = extract(line, "jobId")
        let text = extract(line, "text")
        let normalized = text.toLowerAscii().replace(" ", "")
        var reversed = ""
        for i in countdown(normalized.len - 1, 0):
          reversed.add(normalized[i])
        let pal = if normalized == reversed: "true" else: "false"
        send("{\"type\":\"JOB_ACCEPTED\",\"jobId\":\"" & jobId & "\",\"status\":\"running\"}")
        send("{\"type\":\"JOB_LOG\",\"jobId\":\"" & jobId & "\",\"severity\":\"info\",\"message\":\"starting text.palindrome\"}")
        send("{\"type\":\"JOB_RESULT\",\"jobId\":\"" & jobId & "\",\"output\":{\"palindrome\":" & pal & "}}")
    elif line.contains("\"type\":\"JOB_CANCEL\""):
      let jobId = extract(line, "jobId")
      let useJobId = if jobId.len == 0: "job-unknown" else: jobId
      send("{\"type\":\"JOB_CANCELLED\",\"jobId\":\"" & useJobId & "\",\"status\":\"cancelled\"}")
    elif line.contains("\"type\":\"SHUTDOWN\""):
      send("{\"type\":\"SHUTDOWN_ACK\",\"workerId\":\"nim-palindrome-01\",\"status\":\"stopped\"}")
      break
