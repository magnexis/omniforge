import groovy.json.JsonOutput
import groovy.json.JsonSlurper

def sendMessage = { payload ->
    println(JsonOutput.toJson(payload))
    System.out.flush()
}

def toCamelCase = { String text ->
    def parts = text.toLowerCase().split(/[^a-z0-9]+/).findAll { !it.isEmpty() }
    if (parts.isEmpty()) {
        return ""
    }
    parts.head() + parts.tail().collect { it.capitalize() }.join("")
}

System.in.eachLine { line ->
    def message = new JsonSlurper().parseText(line) as Map
    switch (message.type) {
        case "HELLO":
            sendMessage([
                type: "WELCOME",
                protocol: "ofp/1",
                workerId: "groovy-camel-01",
            ])
            sendMessage([
                type: "REGISTER",
                protocol: "ofp/1",
                workerId: "groovy-camel-01",
                language: "groovy",
                runtimeVersion: "4.0.32",
                workerVersion: "0.1.0",
                capabilities: [[name: "text.camel-case"]],
            ])
            break
        case "REGISTER_ACK":
            break
        case "JOB_START":
            if (message.capability != "text.camel-case") {
                sendMessage([type: "JOB_ERROR", jobId: message.jobId, error: "unsupported capability"])
                break
            }
            sendMessage([type: "JOB_ACCEPTED", jobId: message.jobId])
            sendMessage([type: "JOB_LOG", jobId: message.jobId, level: "info", message: "converting text to camelCase"])
            def text = String.valueOf((message.input ?: [:]).text ?: "")
            sendMessage([
                type: "JOB_RESULT",
                jobId: message.jobId,
                output: [camel: toCamelCase(text)],
            ])
            break
        case "JOB_CANCEL":
            sendMessage([type: "JOB_CANCELLED", jobId: message.jobId])
            break
        case "SHUTDOWN":
            sendMessage([type: "SHUTDOWN_ACK", workerId: "groovy-camel-01"])
            System.exit(0)
    }
}
