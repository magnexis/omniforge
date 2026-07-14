# OFP v1

OFP, the Omniforge Protocol, is a newline-delimited JSON protocol for coordinator-to-worker communication.

## Transport

- UTF-8 JSON
- one message per line
- request and response order preserved on a connection
- current transport: stdio
- future transport targets: local sockets, TCP, WebSocket, MessagePack

## Message Envelope

Every OFP message must include:

- `type`

These fields are strongly recommended for all messages:

- `protocol`
- `messageId`
- `timestamp`
- `correlationId`
- `parentMessageId`
- `workerId`
- `jobId`
- `metadata`

## Lifecycle

1. Coordinator sends `HELLO`
2. Worker replies with `WELCOME` or `REGISTER`
3. Worker registers with `REGISTER`
4. Coordinator may acknowledge with `REGISTER_ACK`
5. Either side may exchange `CAPABILITIES`, `HEARTBEAT`, `HEALTH_REPORT`, and `PING` or `PONG`
6. Coordinator dispatches `JOB_START`
7. Worker may reply with `JOB_ACCEPTED`, `JOB_PROGRESS`, `JOB_LOG`, `JOB_STREAM`, `ARTIFACT_REF`, `JOB_RESULT`, or `JOB_ERROR`
8. Coordinator may issue `JOB_CANCEL`
9. Worker may reply with `JOB_CANCELLED`
10. Coordinator sends `SHUTDOWN`
11. Worker replies with `SHUTDOWN_ACK`

## Message Types

OFP v1 now defines 31 message types.

### Handshake And Session

- `HELLO`
- `WELCOME`
- `REGISTER`
- `REGISTER_ACK`
- `PING`
- `PONG`
- `HEARTBEAT`
- `HEALTH_REPORT`
- `SHUTDOWN`
- `SHUTDOWN_ACK`

### Discovery And Planning

- `CAPABILITIES`
- `CAPABILITY_QUERY`
- `CAPABILITY_RESPONSE`
- `WORKER_STATUS`
- `METRICS_SNAPSHOT`

### Job Execution

- `JOB_START`
- `JOB_ACCEPTED`
- `JOB_PROGRESS`
- `JOB_LOG`
- `JOB_STREAM`
- `JOB_RESULT`
- `JOB_ERROR`
- `JOB_CANCEL`
- `JOB_CANCELLED`

### Artifact Transfer

- `ARTIFACT_PUT`
- `ARTIFACT_GET`
- `ARTIFACT_REF`
- `ARTIFACT_CHUNK`
- `ARTIFACT_COMPLETE`

### Diagnostics And Tracing

- `TRACE_START`
- `TRACE_STOP`

## Required Core Messages

The minimum interoperable worker set remains:

- `HELLO`
- `REGISTER`
- `JOB_START`
- `JOB_RESULT` or `JOB_ERROR`
- `SHUTDOWN`

The recommended baseline set for new workers is:

- `WELCOME`
- `REGISTER_ACK`
- `HEARTBEAT`
- `HEALTH_REPORT`
- `JOB_ACCEPTED`
- `JOB_PROGRESS`
- `JOB_LOG`
- `JOB_CANCEL`
- `JOB_CANCELLED`
- `SHUTDOWN_ACK`

## Core Message Examples

### HELLO

```json
{
  "type": "HELLO",
  "protocol": "ofp/1",
  "messageId": "msg-1",
  "timestamp": "2026-07-14T12:00:00Z"
}
```

### WELCOME

```json
{
  "type": "WELCOME",
  "protocol": "ofp/1",
  "messageId": "msg-2",
  "parentMessageId": "msg-1",
  "workerId": "python-data-01",
  "metadata": {
    "session": "local-stdio",
    "compatible": true
  }
}
```

### REGISTER

```json
{
  "type": "REGISTER",
  "protocol": "ofp/1",
  "workerId": "python-data-01",
  "language": "python",
  "runtimeVersion": "3.x",
  "workerVersion": "0.1.0",
  "capabilities": [
    {
      "name": "data.csv-transform",
      "inputSchema": "csv-transform-request",
      "outputSchema": "csv-transform-result"
    }
  ],
  "limits": {
    "maxInputBytes": 10485760,
    "concurrency": 1
  }
}
```

### REGISTER_ACK

```json
{
  "type": "REGISTER_ACK",
  "protocol": "ofp/1",
  "workerId": "python-data-01",
  "status": "accepted",
  "metadata": {
    "scheduler": "local-first",
    "registryVersion": "1"
  }
}
```

### JOB_START

```json
{
  "type": "JOB_START",
  "protocol": "ofp/1",
  "jobId": "job-1",
  "capability": "data.csv-transform",
  "deadline": "2026-07-14T12:05:00Z",
  "input": {
    "inputPath": "examples/data/customers.csv"
  }
}
```

### JOB_ACCEPTED

```json
{
  "type": "JOB_ACCEPTED",
  "jobId": "job-1",
  "workerId": "python-data-01",
  "status": "running",
  "metadata": {
    "queueDepth": 0
  }
}
```

### JOB_PROGRESS

```json
{
  "type": "JOB_PROGRESS",
  "jobId": "job-1",
  "progress": 0.5,
  "metadata": {
    "stage": "cleaning"
  }
}
```

### JOB_LOG

```json
{
  "type": "JOB_LOG",
  "jobId": "job-1",
  "severity": "info",
  "message": "normalized 200 rows"
}
```

### JOB_STREAM

```json
{
  "type": "JOB_STREAM",
  "jobId": "job-1",
  "streamId": "rows",
  "sequence": 3,
  "output": {
    "row": {
      "id": 42,
      "tier": "gold"
    }
  }
}
```

### JOB_RESULT

```json
{
  "type": "JOB_RESULT",
  "jobId": "job-1",
  "output": {}
}
```

### JOB_ERROR

```json
{
  "type": "JOB_ERROR",
  "jobId": "job-1",
  "error": "invalid input",
  "code": "INVALID_INPUT",
  "retryable": false
}
```

### JOB_CANCEL

```json
{
  "type": "JOB_CANCEL",
  "jobId": "job-1",
  "reason": "deadline exceeded"
}
```

### JOB_CANCELLED

```json
{
  "type": "JOB_CANCELLED",
  "jobId": "job-1",
  "status": "cancelled"
}
```

### ARTIFACT_REF

```json
{
  "type": "ARTIFACT_REF",
  "jobId": "job-1",
  "artifactId": "artifact-9",
  "contentType": "application/gzip",
  "checksum": "sha256:abc123",
  "uri": "artifact://local/job-1/output.gz"
}
```

### HEARTBEAT

```json
{
  "type": "HEARTBEAT",
  "workerId": "python-data-01",
  "status": "healthy",
  "metadata": {
    "activeJobs": 1,
    "queueDepth": 0
  }
}
```

### SHUTDOWN

```json
{
  "type": "SHUTDOWN",
  "protocol": "ofp/1"
}
```

### SHUTDOWN_ACK

```json
{
  "type": "SHUTDOWN_ACK",
  "workerId": "python-data-01",
  "status": "stopped"
}
```

## Design Notes

- OFP v1 favors accessibility over compactness
- workers are independent processes
- capability names are stable string identifiers
- worker-specific data lives in `input` and `output`
- artifact-heavy and streaming workflows should use explicit artifact and stream messages rather than overloading `JOB_RESULT`
- the current coordinator implements a smaller subset than the full protocol surface documented here

## Implementation Status

Implemented broadly across current workers:

- `HELLO`
- `REGISTER`
- `JOB_START`
- `JOB_PROGRESS`
- `JOB_RESULT`
- `JOB_ERROR`
- `SHUTDOWN`

Defined in OFP v1 and available for phased adoption:

- `WELCOME`
- `REGISTER_ACK`
- `CAPABILITIES`
- `CAPABILITY_QUERY`
- `CAPABILITY_RESPONSE`
- `PING`
- `PONG`
- `HEARTBEAT`
- `HEALTH_REPORT`
- `WORKER_STATUS`
- `METRICS_SNAPSHOT`
- `JOB_ACCEPTED`
- `JOB_LOG`
- `JOB_STREAM`
- `JOB_CANCEL`
- `JOB_CANCELLED`
- `ARTIFACT_PUT`
- `ARTIFACT_GET`
- `ARTIFACT_REF`
- `ARTIFACT_CHUNK`
- `ARTIFACT_COMPLETE`
- `TRACE_START`
- `TRACE_STOP`
- `SHUTDOWN_ACK`
