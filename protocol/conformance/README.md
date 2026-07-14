# Conformance

Workers are conformant when they:

- reply to `HELLO` with `REGISTER`
- accept `JOB_START`
- return `JOB_RESULT` or `JOB_ERROR`
- shut down cleanly on `SHUTDOWN`

Recommended conformance for new workers:

- optionally emit `WELCOME` before `REGISTER`
- tolerate `CAPABILITIES`, `PING`, and `JOB_CANCEL`
- emit `JOB_ACCEPTED` before long-running work
- emit `JOB_PROGRESS` or `JOB_LOG` for long-running jobs
- emit `SHUTDOWN_ACK` on clean exit

The current end-to-end test suite now also exercises the upgraded handshake and cancellation path through the Python worker, while the broader OFP v1 message surface remains available for phased adoption across the rest of the worker set.
