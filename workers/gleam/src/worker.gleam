import gleam/io
import gleam/string

@external(erlang, "worker_io", "read_line")
fn read_line() -> String

pub fn main() {
  loop()
}

fn loop() {
  let line = read_line()
  case string.trim(line) {
    "eof" -> Nil
    trimmed -> {
      handle_line(trimmed)
      loop()
    }
  }
}

fn handle_line(line: String) {
  case string.contains(line, "\"type\":\"HELLO\"") {
    True ->
      io.println(
        "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"gleam-lower-01\",\"language\":\"gleam\",\"runtimeVersion\":\"1.17.0\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"text.lower-gleam\"}]}"
      )

    False ->
      case string.contains(line, "\"type\":\"JOB_START\"") {
        True ->
          case string.contains(line, "\"capability\":\"text.lower-gleam\"") {
            True -> {
              let job_id = extract(line, "\"jobId\":\"")
              let text = extract(line, "\"text\":\"")
              let lowered = string.lowercase(text)
              io.println(
                "{\"type\":\"JOB_RESULT\",\"jobId\":\"" <>
                  job_id <>
                  "\",\"output\":{\"lowered\":\"" <>
                  lowered <>
                  "\"}}"
              )
            }

            False ->
              io.println(
                "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}"
              )
          }

        False -> Nil
      }
  }
}

fn extract(line: String, marker: String) -> String {
  case string.split_once(line, marker) {
    Error(_) -> ""
    Ok(#(_, rest)) ->
      case string.split_once(rest, "\"") {
        Error(_) -> ""
        Ok(#(value, _)) -> value
      }
  }
}
