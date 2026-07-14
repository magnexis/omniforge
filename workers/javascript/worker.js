const readline = require("readline");

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

function send(message) {
  process.stdout.write(JSON.stringify(message) + "\n");
}

const register = {
  type: "REGISTER",
  protocol: "ofp/1",
  workerId: "javascript-validate-01",
  language: "javascript",
  runtimeVersion: process.version,
  workerVersion: "0.1.0",
  capabilities: [{ name: "data.validate" }],
};

const welcome = {
  type: "WELCOME",
  protocol: "ofp/1",
  workerId: "javascript-validate-01",
  language: "javascript",
  runtimeVersion: process.version,
  workerVersion: "0.1.0",
  status: "ready",
};

rl.on("line", (line) => {
  const message = JSON.parse(line);
  if (message.type === "HELLO") {
    send(welcome);
    send(register);
    return;
  }
  if (message.type === "REGISTER_ACK") {
    return;
  }
  if (message.type === "JOB_START") {
    if (message.capability !== "data.validate") {
      send({ type: "JOB_ERROR", jobId: message.jobId, error: "unsupported capability" });
      return;
    }
    send({ type: "JOB_ACCEPTED", jobId: message.jobId, status: "running" });
    send({ type: "JOB_LOG", jobId: message.jobId, severity: "info", message: "starting data.validate" });
    const payload = message.input.previous;
    const rows = payload.rows || [];
    const invalid = rows.filter((row) => !row.customer_id || !row.risk);
    send({ type: "JOB_PROGRESS", jobId: message.jobId, progress: 0.75, metadata: { stage: "validation" } });
    send({
      type: "JOB_RESULT",
      jobId: message.jobId,
      output: {
        rows,
        valid: invalid.length === 0,
        invalidCount: invalid.length,
        counts: payload.counts || {},
      },
    });
    return;
  }
  if (message.type === "SHUTDOWN") {
    send({ type: "SHUTDOWN_ACK", workerId: "javascript-validate-01", status: "stopped" });
    process.exit(0);
  }
});
