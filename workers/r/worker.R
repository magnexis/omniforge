extract_value <- function(line, pattern) {
  match <- regmatches(line, regexec(pattern, line))[[1]]
  if (length(match) < 2) "" else match[2]
}

send_json <- function(text) {
  cat(text, "\n", sep = "")
  flush.console()
}

con <- file("stdin", open = "r")
while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
  if (grepl('"type":"HELLO"', line, fixed = TRUE)) {
    send_json('{"type":"WELCOME","protocol":"ofp/1","workerId":"r-median-01"}')
    send_json('{"type":"REGISTER","protocol":"ofp/1","workerId":"r-median-01","language":"r","runtimeVersion":"4.6.1","workerVersion":"0.1.0","capabilities":[{"name":"math.median"}]}')
  } else if (grepl('"type":"REGISTER_ACK"', line, fixed = TRUE)) {
    next
  } else if (grepl('"type":"JOB_START"', line, fixed = TRUE)) {
    if (!grepl('"capability":"math.median"', line, fixed = TRUE)) {
      send_json('{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}')
    } else {
      job_id <- extract_value(line, '"jobId":"([^"]+)"')
      send_json(sprintf('{"type":"JOB_ACCEPTED","jobId":"%s"}', job_id))
      send_json(sprintf('{"type":"JOB_LOG","jobId":"%s","level":"info","message":"calculating median"}', job_id))
      numbers_blob <- sub('.*"numbers"\\s*:\\s*\\[([^]]*)\\].*', '\\1', line)
      if (identical(numbers_blob, line)) numbers_blob <- ""
      parts <- if (nzchar(numbers_blob)) strsplit(numbers_blob, ",")[[1]] else character()
      values <- as.numeric(trimws(parts))
      values <- values[!is.na(values)]
      send_json(sprintf(
        '{"type":"JOB_RESULT","jobId":"%s","output":{"count":%d,"median":%s}}',
        job_id,
        length(values),
        format(median(values), scientific = FALSE, trim = TRUE)
      ))
    }
  } else if (grepl('"type":"JOB_CANCEL"', line, fixed = TRUE)) {
    job_id <- extract_value(line, '"jobId":"([^"]+)"')
    send_json(sprintf('{"type":"JOB_CANCELLED","jobId":"%s"}', job_id))
  } else if (grepl('"type":"SHUTDOWN"', line, fixed = TRUE)) {
    send_json('{"type":"SHUTDOWN_ACK","workerId":"r-median-01"}')
    quit(save = "no", status = 0)
  }
}
