import json
import sys


WORKER_ID = "brainfuck-echo-01"


def send(message):
    sys.stdout.write(json.dumps(message) + "\n")
    sys.stdout.flush()


def run_brainfuck(program: str, input_data: str = "", max_steps: int = 100000):
    tape = [0]
    ptr = 0
    pc = 0
    steps = 0
    input_index = 0
    output = []
    bracket_map = {}
    stack = []

    for index, char in enumerate(program):
        if char == "[":
            stack.append(index)
        elif char == "]":
            if not stack:
                raise ValueError("unmatched closing bracket")
            start = stack.pop()
            bracket_map[start] = index
            bracket_map[index] = start
    if stack:
        raise ValueError("unmatched opening bracket")

    while pc < len(program):
        steps += 1
        if steps > max_steps:
            raise ValueError("step limit exceeded")

        op = program[pc]
        if op == ">":
            ptr += 1
            if ptr == len(tape):
                tape.append(0)
        elif op == "<":
            ptr = max(0, ptr - 1)
        elif op == "+":
            tape[ptr] = (tape[ptr] + 1) % 256
        elif op == "-":
            tape[ptr] = (tape[ptr] - 1) % 256
        elif op == ".":
            output.append(chr(tape[ptr]))
        elif op == ",":
            tape[ptr] = ord(input_data[input_index]) if input_index < len(input_data) else 0
            input_index += 1
        elif op == "[":
            if tape[ptr] == 0:
                pc = bracket_map[pc]
        elif op == "]":
            if tape[ptr] != 0:
                pc = bracket_map[pc]
        pc += 1

    return {
        "output": "".join(output),
        "steps": steps,
        "cellsUsed": len(tape),
    }


for raw_line in sys.stdin:
    line = raw_line.strip()
    if not line:
        continue
    message = json.loads(line)
    msg_type = message.get("type")

    if msg_type == "HELLO":
        send({"type": "WELCOME", "protocol": "ofp/1", "workerId": WORKER_ID})
        send(
            {
                "type": "REGISTER",
                "protocol": "ofp/1",
                "workerId": WORKER_ID,
                "language": "brainfuck",
                "runtimeVersion": "embedded-python-interpreter",
                "workerVersion": "0.1.0",
                "capabilities": [{"name": "esolang.brainfuck-run"}],
            }
        )
    elif msg_type == "REGISTER_ACK":
        continue
    elif msg_type == "JOB_START":
        job_id = message.get("jobId", "job-unknown")
        if message.get("capability") != "esolang.brainfuck-run":
            send({"type": "JOB_ERROR", "jobId": job_id, "error": "unsupported capability"})
            continue
        send({"type": "JOB_ACCEPTED", "jobId": job_id})
        send({"type": "JOB_LOG", "jobId": job_id, "level": "info", "message": "executing brainfuck program"})
        try:
            payload = message.get("input", {})
            result = run_brainfuck(payload.get("program", ""), payload.get("stdin", ""))
            send({"type": "JOB_RESULT", "jobId": job_id, "output": result})
        except Exception as exc:
            send({"type": "JOB_ERROR", "jobId": job_id, "error": str(exc)})
    elif msg_type == "JOB_CANCEL":
        send({"type": "JOB_CANCELLED", "jobId": message.get("jobId", "job-unknown")})
    elif msg_type == "SHUTDOWN":
        send({"type": "SHUTDOWN_ACK", "workerId": WORKER_ID})
        break
