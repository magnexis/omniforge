use std::io::{self, BufRead, Write};

fn send(line: &str) {
    println!("{line}");
    io::stdout().flush().unwrap();
}

fn rle_encode(input: &str) -> String {
    let mut chars = input.chars();
    let Some(mut current) = chars.next() else {
        return String::new();
    };
    let mut count = 1usize;
    let mut out = String::new();
    for ch in chars {
        if ch == current {
            count += 1;
        } else {
            out.push(current);
            out.push_str(&count.to_string());
            current = ch;
            count = 1;
        }
    }
    out.push(current);
    out.push_str(&count.to_string());
    out
}

fn main() {
    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        let line = line.unwrap();
        if line.contains("\"type\":\"HELLO\"") {
            send("{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"rust-compress-01\",\"language\":\"rust\",\"runtimeVersion\":\"stable\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"system.compress\"}]}");
        } else if line.contains("\"type\":\"JOB_START\"") {
            if !line.contains("\"capability\":\"system.compress\"") {
                send("{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}");
                continue;
            }
            let job_id = line.split("\"jobId\":\"").nth(1).and_then(|s| s.split('"').next()).unwrap_or("job-unknown");
            let payload = line.split("\"previous\":").nth(1).unwrap_or("{}");
            let cleaned = payload.trim_end_matches('}').to_string();
            let encoded = rle_encode(&cleaned);
            send(&format!("{{\"type\":\"JOB_PROGRESS\",\"jobId\":\"{}\",\"progress\":1.0,\"metadata\":{{\"stage\":\"compress\"}}}}", job_id));
            send(&format!("{{\"type\":\"JOB_RESULT\",\"jobId\":\"{}\",\"output\":{{\"algorithm\":\"rle\",\"compressed\":\"{}\",\"sourceBytes\":{},\"compressedBytes\":{}}}}}", job_id, encoded.replace("\\", "\\\\").replace("\"", "\\\""), cleaned.len(), encoded.len()));
        } else if line.contains("\"type\":\"SHUTDOWN\"") {
            break;
        }
    }
}
