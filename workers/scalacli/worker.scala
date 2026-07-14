import scala.io.StdIn

object Worker {
  private def send(message: String): Unit = {
    println(message)
    Console.flush()
  }

  private def extract(line: String, marker: String): String = {
    val idx = line.indexOf(marker)
    if (idx < 0) "" else {
      val rest = line.substring(idx + marker.length)
      val end = rest.indexOf('"')
      if (end < 0) "" else rest.substring(0, end)
    }
  }

  def main(args: Array[String]): Unit = {
    Iterator.continually(StdIn.readLine()).takeWhile(_ != null).foreach { line =>
      if (line.contains("\"type\":\"HELLO\"")) {
        send("""{"type":"REGISTER","protocol":"ofp/1","workerId":"scala-cli-lines-01","language":"scalacli","runtimeVersion":"1.15.0","workerVersion":"0.1.0","capabilities":[{"name":"text.lines-scala"}]}""")
      } else if (line.contains("\"type\":\"JOB_START\"")) {
        if (!line.contains("\"capability\":\"text.lines-scala\"")) {
          send("""{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}""")
        } else {
          val jobId = {
            val value = extract(line, "\"jobId\":\"")
            if (value.isEmpty) "job-unknown" else value
          }
          val text = extract(line, "\"text\":\"")
          val lineCount =
            if (text.isEmpty) 0
            else text.split("\\\\n", -1).length
          send(s"""{"type":"JOB_RESULT","jobId":"$jobId","output":{"lines":$lineCount}}""")
        }
      } else if (line.contains("\"type\":\"SHUTDOWN\"")) {
        sys.exit(0)
      }
    }
  }
}
