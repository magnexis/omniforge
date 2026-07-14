require "json"

REGISTER = {
  type: "REGISTER",
  protocol: "ofp/1",
  workerId: "ruby-rules-01",
  language: "ruby",
  runtimeVersion: RUBY_VERSION,
  workerVersion: "0.1.0",
  capabilities: [{ name: "rules.evaluate" }]
}

WELCOME = {
  type: "WELCOME",
  protocol: "ofp/1",
  workerId: "ruby-rules-01",
  language: "ruby",
  runtimeVersion: RUBY_VERSION,
  workerVersion: "0.1.0",
  status: "ready"
}

def send_message(message)
  STDOUT.puts(JSON.generate(message))
  STDOUT.flush
end

ARGF.each_line do |line|
  message = JSON.parse(line)
  case message["type"]
  when "HELLO"
    send_message(WELCOME)
    send_message(REGISTER)
  when "REGISTER_ACK"
    next
  when "JOB_START"
    if message["capability"] != "rules.evaluate"
      send_message(type: "JOB_ERROR", jobId: message["jobId"], error: "unsupported capability")
      next
    end

    send_message(type: "JOB_ACCEPTED", jobId: message["jobId"], status: "running")
    send_message(type: "JOB_LOG", jobId: message["jobId"], severity: "info", message: "starting rules.evaluate")

    rows = message["input"]["previous"]["rows"]
    classified = rows.map do |row|
      risk = if !row["active"]
               "inactive"
             elsif row["amount"] >= 1000
               "priority"
             elsif row["amount"] >= 500
               "standard"
             else
               "low"
             end
      row.merge("risk" => risk)
    end

    send_message(type: "JOB_PROGRESS", jobId: message["jobId"], progress: 0.5, metadata: { stage: "classification" })
    send_message(
      type: "JOB_RESULT",
      jobId: message["jobId"],
      output: {
        rows: classified,
        counts: classified.group_by { |row| row["risk"] }.transform_values(&:length)
      }
    )
  when "SHUTDOWN"
    send_message(type: "SHUTDOWN_ACK", workerId: "ruby-rules-01", status: "stopped")
    break
  end
end
