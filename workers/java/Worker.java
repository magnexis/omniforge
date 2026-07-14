import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Worker {
    private static final Pattern JOB_ID = Pattern.compile("\"jobId\"\\s*:\\s*\"([^\"]+)\"");
    private static final Pattern TEXT = Pattern.compile("\"text\"\\s*:\\s*\"([^\"]*)\"");

    private static void send(String payload) {
        System.out.println(payload);
        System.out.flush();
    }

    private static String extract(Pattern pattern, String line, String fallback) {
        Matcher matcher = pattern.matcher(line);
        return matcher.find() ? matcher.group(1) : fallback;
    }

    public static void main(String[] args) throws IOException {
        BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
        String line;
        while ((line = reader.readLine()) != null) {
            if (line.contains("\"type\":\"HELLO\"")) {
                send("{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"java-wordcount-01\",\"language\":\"java\",\"runtimeVersion\":\"21\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"text.word-count\"}]}");
            } else if (line.contains("\"type\":\"JOB_START\"")) {
                if (!line.contains("\"capability\":\"text.word-count\"")) {
                    send("{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}");
                    continue;
                }
                String jobId = extract(JOB_ID, line, "job-unknown");
                String text = extract(TEXT, line, "");
                int words = text.trim().isEmpty() ? 0 : text.trim().split("\\s+").length;
                int chars = text.length();
                send("{\"type\":\"JOB_PROGRESS\",\"jobId\":\"" + jobId + "\",\"progress\":0.5,\"metadata\":{\"stage\":\"counting\"}}");
                send("{\"type\":\"JOB_RESULT\",\"jobId\":\"" + jobId + "\",\"output\":{\"words\":" + words + ",\"characters\":" + chars + "}}");
            } else if (line.contains("\"type\":\"SHUTDOWN\"")) {
                break;
            }
        }
    }
}
