(defn send [s]
  (print s)
  (flush))

(defn extract [line marker]
  (def start (string/find line marker))
  (if start
    (let [rest (string/slice line (+ start (length marker)))
          stop (string/find rest "\"")]
      (if stop (string/slice rest 0 stop) ""))
    ""))

(while true
  (def line (file/read stdin :line))
  (when (nil? line) (break))
  (if (string/find line "\"type\":\"HELLO\"")
    (do
      (send "{\"type\":\"WELCOME\",\"protocol\":\"ofp/1\",\"workerId\":\"janet-lower-01\",\"language\":\"janet\",\"runtimeVersion\":\"1.41.2\",\"workerVersion\":\"0.1.0\",\"status\":\"ready\"}")
      (send "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"janet-lower-01\",\"language\":\"janet\",\"runtimeVersion\":\"1.41.2\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"text.lower-janet\"}]}"))
    (if (string/find line "\"type\":\"JOB_START\"")
      (if (not (string/find line "\"capability\":\"text.lower-janet\""))
        (send "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}")
        (let [jobid (extract line "\"jobId\":\"")
              text (extract line "\"text\":\"")
              lowered (string/ascii-lower text)]
          (def use-jobid (if (= jobid "") "job-unknown" jobid))
          (send (string "{\"type\":\"JOB_ACCEPTED\",\"jobId\":\"" use-jobid "\",\"status\":\"running\"}"))
          (send (string "{\"type\":\"JOB_LOG\",\"jobId\":\"" use-jobid "\",\"severity\":\"info\",\"message\":\"starting text.lower-janet\"}"))
          (send (string "{\"type\":\"JOB_RESULT\",\"jobId\":\""
                        use-jobid
                        "\",\"output\":{\"lowered\":\""
                        lowered
                        "\"}}"))))
      (if (string/find line "\"type\":\"JOB_CANCEL\"")
        (let [jobid (extract line "\"jobId\":\"")]
          (send (string "{\"type\":\"JOB_CANCELLED\",\"jobId\":\""
                        (if (= jobid "") "job-unknown" jobid)
                        "\",\"status\":\"cancelled\"}")))
        (if (string/find line "\"type\":\"REGISTER_ACK\"")
          nil
          (when (string/find line "\"type\":\"SHUTDOWN\"")
            (send "{\"type\":\"SHUTDOWN_ACK\",\"workerId\":\"janet-lower-01\",\"status\":\"stopped\"}")
            (break)))))))
