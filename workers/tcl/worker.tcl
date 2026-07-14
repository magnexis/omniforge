proc send {json} {
    puts $json
    flush stdout
}

while {[gets stdin line] >= 0} {
    if {[string first "\"type\":\"HELLO\"" $line] >= 0} {
        send {{"type":"WELCOME","protocol":"ofp/1","workerId":"tcl-trim-01","language":"tcl","runtimeVersion":"8.6","workerVersion":"0.1.0","status":"ready"}}
        send {{"type":"REGISTER","protocol":"ofp/1","workerId":"tcl-trim-01","language":"tcl","runtimeVersion":"8.6","workerVersion":"0.1.0","capabilities":[{"name":"text.trim"}]}}
    } elseif {[string first "\"type\":\"REGISTER_ACK\"" $line] >= 0} {
        continue
    } elseif {[string first "\"type\":\"JOB_START\"" $line] >= 0} {
        if {[string first "\"capability\":\"text.trim\"" $line] < 0} {
            send "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}"
        } else {
            regexp {\"jobId\":\"([^\"]+)\"} $line _ jobId
            regexp {\"text\":\"([^\"]*)\"} $line _ text
            send "{\"type\":\"JOB_ACCEPTED\",\"jobId\":\"$jobId\",\"status\":\"running\"}"
            send "{\"type\":\"JOB_LOG\",\"jobId\":\"$jobId\",\"severity\":\"info\",\"message\":\"starting text.trim\"}"
            set trimmed [string trim $text]
            regsub -all {\\} $trimmed {\\\\} escaped
            regsub -all {"} $escaped {\\"} escaped
            send "{\"type\":\"JOB_RESULT\",\"jobId\":\"$jobId\",\"output\":{\"trimmed\":\"$escaped\"}}"
        }
    } elseif {[string first "\"type\":\"JOB_CANCEL\"" $line] >= 0} {
        regexp {\"jobId\":\"([^\"]+)\"} $line _ jobId
        if {![info exists jobId] || $jobId eq ""} {
            set jobId "job-unknown"
        }
        send "{\"type\":\"JOB_CANCELLED\",\"jobId\":\"$jobId\",\"status\":\"cancelled\"}"
    } elseif {[string first "\"type\":\"SHUTDOWN\"" $line] >= 0} {
        send {{"type":"SHUTDOWN_ACK","workerId":"tcl-trim-01","status":"stopped"}}
        exit 0
    }
}
