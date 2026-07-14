#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void send(const char *payload) {
    puts(payload);
    fflush(stdout);
}

static void extract_value(const char *line, const char *key, char *buffer, size_t size) {
    const char *start = strstr(line, key);
    if (!start) {
        buffer[0] = '\0';
        return;
    }
    start += strlen(key);
    const char *end = strchr(start, '"');
    if (!end) {
        buffer[0] = '\0';
        return;
    }
    size_t len = (size_t)(end - start);
    if (len >= size) {
        len = size - 1;
    }
    memcpy(buffer, start, len);
    buffer[len] = '\0';
}

static unsigned long checksum_file(const char *path) {
    FILE *file = fopen(path, "rb");
    if (!file) {
        return 0;
    }
    unsigned long hash = 2166136261u;
    int ch;
    while ((ch = fgetc(file)) != EOF) {
        hash ^= (unsigned char)ch;
        hash *= 16777619u;
    }
    fclose(file);
    return hash;
}

int main(void) {
    char line[8192];
    while (fgets(line, sizeof(line), stdin)) {
        if (strstr(line, "\"type\":\"HELLO\"")) {
            send("{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"c-hash-01\",\"language\":\"c\",\"runtimeVersion\":\"clang\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"system.file-hash\"}]}");
        } else if (strstr(line, "\"type\":\"JOB_START\"")) {
            if (!strstr(line, "\"capability\":\"system.file-hash\"")) {
                send("{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}");
                continue;
            }
            char job_id[128];
            char path[4096];
            extract_value(line, "\"jobId\":\"", job_id, sizeof(job_id));
            extract_value(line, "\"path\":\"", path, sizeof(path));
            unsigned long hash = checksum_file(path);
            if (hash == 0) {
                printf("{\"type\":\"JOB_ERROR\",\"jobId\":\"%s\",\"error\":\"could not open file\"}\n", job_id[0] ? job_id : "job-unknown");
                fflush(stdout);
                continue;
            }
            printf("{\"type\":\"JOB_RESULT\",\"jobId\":\"%s\",\"output\":{\"algorithm\":\"fnv1a32\",\"hash\":\"%08lx\"}}\n", job_id[0] ? job_id : "job-unknown", hash);
            fflush(stdout);
        } else if (strstr(line, "\"type\":\"SHUTDOWN\"")) {
            break;
        }
    }
    return 0;
}
