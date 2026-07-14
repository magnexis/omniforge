import std.stdio;
import std.string;
import std.conv;

string extract(string line, string marker) {
    auto start = line.indexOf(marker);
    if (start < 0) return "";
    auto rest = line[start + cast(int) marker.length .. $];
    auto stop = rest.indexOf('"');
    if (stop < 0) return "";
    return rest[0 .. stop];
}

void send(string msg) {
    writeln(msg);
    stdout.flush();
}

void main() {
    string line;
    while ((line = stdin.readln()) !is null) {
        line = chomp(line);
        if (line.indexOf("\"type\":\"HELLO\"") >= 0) {
            send("{\"type\":\"WELCOME\",\"protocol\":\"ofp/1\",\"workerId\":\"d-range-01\",\"language\":\"d\",\"runtimeVersion\":\"2.112.0\",\"workerVersion\":\"0.1.0\",\"status\":\"ready\"}");
            send("{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"d-range-01\",\"language\":\"d\",\"runtimeVersion\":\"2.112.0\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"math.range\"}]}");
        } else if (line.indexOf("\"type\":\"REGISTER_ACK\"") >= 0) {
            continue;
        } else if (line.indexOf("\"type\":\"JOB_START\"") >= 0) {
            if (line.indexOf("\"capability\":\"math.range\"") < 0) {
                send("{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}");
            } else {
                auto jobId = extract(line, "\"jobId\":\"");
                if (jobId.length == 0) jobId = "job-unknown";
                send("{\"type\":\"JOB_ACCEPTED\",\"jobId\":\"" ~ jobId ~ "\",\"status\":\"running\"}");
                send("{\"type\":\"JOB_LOG\",\"jobId\":\"" ~ jobId ~ "\",\"severity\":\"info\",\"message\":\"starting math.range\"}");
                auto start = line.indexOf("\"numbers\":[");
                double minVal = 0;
                double maxVal = 0;
                bool first = true;
                if (start >= 0) {
                    auto body = line[start + 11 .. $];
                    auto end = body.indexOf(']');
                    if (end >= 0) {
                        foreach (piece; body[0 .. end].split(",")) {
                            auto trimmed = piece.strip();
                            if (trimmed.length == 0) continue;
                            auto value = to!double(trimmed);
                            if (first) {
                                minVal = value;
                                maxVal = value;
                                first = false;
                            } else {
                                if (value < minVal) minVal = value;
                                if (value > maxVal) maxVal = value;
                            }
                        }
                    }
                }
                auto span = first ? 0 : maxVal - minVal;
                send("{\"type\":\"JOB_RESULT\",\"jobId\":\"" ~ jobId ~ "\",\"output\":{\"min\":" ~ to!string(minVal) ~ ",\"max\":" ~ to!string(maxVal) ~ ",\"range\":" ~ to!string(span) ~ "}}");
            }
        } else if (line.indexOf("\"type\":\"JOB_CANCEL\"") >= 0) {
            auto jobId = extract(line, "\"jobId\":\"");
            if (jobId.length == 0) jobId = "job-unknown";
            send("{\"type\":\"JOB_CANCELLED\",\"jobId\":\"" ~ jobId ~ "\",\"status\":\"cancelled\"}");
        } else if (line.indexOf("\"type\":\"SHUTDOWN\"") >= 0) {
            send("{\"type\":\"SHUTDOWN_ACK\",\"workerId\":\"d-range-01\",\"status\":\"stopped\"}");
            break;
        }
    }
}
