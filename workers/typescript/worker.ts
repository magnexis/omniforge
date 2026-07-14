import { createInterface } from "node:readline";

const rl = createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

function send(payload: unknown) {
  process.stdout.write(JSON.stringify(payload) + "\n");
}

rl.on("line", (line) => {
  const message = JSON.parse(line);
  if (message.type === "HELLO") {
    send({
      type: "REGISTER",
      protocol: "ofp/1",
      workerId: "typescript-slug-01",
      language: "typescript",
      runtimeVersion: process.version,
      workerVersion: "0.1.0",
      capabilities: [{ name: "text.slugify" }],
    });
  } else if (message.type === "JOB_START") {
    if (message.capability !== "text.slugify") {
      send({ type: "JOB_ERROR", jobId: message.jobId, error: "unsupported capability" });
      return;
    }
    const text = String(message.input.text ?? "");
    const slug = text.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    send({ type: "JOB_RESULT", jobId: message.jobId, output: { slug } });
  } else if (message.type === "SHUTDOWN") {
    process.exit(0);
  }
});
