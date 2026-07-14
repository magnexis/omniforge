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

  private def extractItems(line: String): List[String] = {
    val marker = "\"items\":["
    val start = line.indexOf(marker)
    if (start < 0) Nil
    else {
      val rest = line.substring(start + marker.length)
      val stop = rest.indexOf(']')
      if (stop < 0) Nil
      else {
        val body = rest.substring(0, stop).trim
        if (body.isEmpty) Nil
        else body.split(",").toList.map(_.trim.stripPrefix("\"").stripSuffix("\""))
      }
    }
  }

  def main(args: Array[String]): Unit = {
    Iterator.continually(StdIn.readLine()).takeWhile(_ != null).foreach { line =>
      if (line.contains("\"type\":\"HELLO\"")) {
        send("""{"type":"WELCOME","protocol":"ofp/1","workerId":"scala-lengths-01"}""")
        send("""{"type":"REGISTER","protocol":"ofp/1","workerId":"scala-lengths-01","language":"scala","runtimeVersion":"scala-cli","workerVersion":"0.1.0","capabilities":[{"name":"text.lengths-scala"}]}""")
      } else if (line.contains("\"type\":\"REGISTER_ACK\"")) {
        ()
      } else if (line.contains("\"type\":\"JOB_START\"")) {
        if (!line.contains("\"capability\":\"text.lengths-scala\"")) {
          val jobId = extract(line, "\"jobId\":\"")
          send(s"""{"type":"JOB_ERROR","jobId":"${if (jobId.nonEmpty) jobId else "job-unknown"}","error":"unsupported capability"}""")
        } else {
          val jobId = {
            val value = extract(line, "\"jobId\":\"")
            if (value.isEmpty) "job-unknown" else value
          }
          val items = extractItems(line)
          send(s"""{"type":"JOB_ACCEPTED","jobId":"$jobId"}""")
          send(s"""{"type":"JOB_LOG","jobId":"$jobId","level":"info","message":"measuring string lengths"}""")
          val lengths = items.map(item => s""""$item":${item.length}""").mkString(",")
          send(s"""{"type":"JOB_RESULT","jobId":"$jobId","output":{"count":${items.length},"lengths":{$lengths}}}""")
        }
      } else if (line.contains("\"type\":\"JOB_CANCEL\"")) {
        val jobId = extract(line, "\"jobId\":\"")
        send(s"""{"type":"JOB_CANCELLED","jobId":"${if (jobId.nonEmpty) jobId else "job-unknown"}"}""")
      } else if (line.contains("\"type\":\"SHUTDOWN\"")) {
        send("""{"type":"SHUTDOWN_ACK","workerId":"scala-lengths-01"}""")
        sys.exit(0)
      }
    }
  }
}
