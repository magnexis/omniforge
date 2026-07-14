function send_message(text)
    println(text)
    flush(stdout)
end

extract(line, pattern) = begin
    match_obj = match(pattern, line)
    match_obj === nothing ? "" : match_obj.captures[1]
end

for line in eachline(stdin)
    if occursin("\"type\":\"HELLO\"", line)
        send_message("{\"type\":\"WELCOME\",\"protocol\":\"ofp/1\",\"workerId\":\"julia-vector-01\"}")
        send_message("{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"julia-vector-01\",\"language\":\"julia\",\"runtimeVersion\":\"1.12.6\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"math.vector-sum\"}]}")
    elseif occursin("\"type\":\"REGISTER_ACK\"", line)
        continue
    elseif occursin("\"type\":\"JOB_START\"", line)
        if !occursin("\"capability\":\"math.vector-sum\"", line)
            send_message("{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}")
            continue
        end
        job_id = extract(line, r"\"jobId\":\"([^\"]+)\"")
        send_message("{\"type\":\"JOB_ACCEPTED\",\"jobId\":\"$(job_id)\"}")
        send_message("{\"type\":\"JOB_LOG\",\"jobId\":\"$(job_id)\",\"level\":\"info\",\"message\":\"summing vector\"}")
        numbers_match = match(r"\"numbers\":\[(.*?)\]", line)
        parts = numbers_match === nothing ? String[] : split(numbers_match.captures[1], ",")
        values = [parse(Float64, strip(part)) for part in parts if !isempty(strip(part))]
        total = sum(values)
        send_message("{\"type\":\"JOB_RESULT\",\"jobId\":\"$(job_id)\",\"output\":{\"count\":$(length(values)),\"sum\":$(total)}}")
    elseif occursin("\"type\":\"JOB_CANCEL\"", line)
        job_id = extract(line, r"\"jobId\":\"([^\"]+)\"")
        send_message("{\"type\":\"JOB_CANCELLED\",\"jobId\":\"$(job_id)\"}")
    elseif occursin("\"type\":\"SHUTDOWN\"", line)
        send_message("{\"type\":\"SHUTDOWN_ACK\",\"workerId\":\"julia-vector-01\"}")
        break
    end
end
