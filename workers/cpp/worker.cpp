#include <algorithm>
#include <iostream>
#include <regex>
#include <sstream>
#include <string>
#include <vector>

static std::string extract_first(const std::string& line, const std::regex& pattern) {
    std::smatch match;
    if (std::regex_search(line, match, pattern)) {
        return match[1].str();
    }
    return "";
}

static std::vector<int> parse_numbers(const std::string& line) {
    std::regex array_pattern("\"numbers\"\\s*:\\s*\\[([^\\]]*)\\]");
    std::smatch match;
    std::vector<int> values;
    if (!std::regex_search(line, match, array_pattern)) {
        return values;
    }
    std::stringstream stream(match[1].str());
    std::string token;
    while (std::getline(stream, token, ',')) {
        values.push_back(std::stoi(token));
    }
    return values;
}

int main() {
    std::string line;
    std::regex job_pattern("\"jobId\"\\s*:\\s*\"([^\"]+)\"");
    while (std::getline(std::cin, line)) {
        if (line.find("\"type\":\"HELLO\"") != std::string::npos) {
            std::cout << "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"cpp-sort-01\",\"language\":\"cpp\",\"runtimeVersion\":\"clang++\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"algorithm.sort\"}]}" << std::endl;
        } else if (line.find("\"type\":\"JOB_START\"") != std::string::npos) {
            if (line.find("\"capability\":\"algorithm.sort\"") == std::string::npos) {
                std::cout << "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}" << std::endl;
                continue;
            }
            auto job_id = extract_first(line, job_pattern);
            auto values = parse_numbers(line);
            std::sort(values.begin(), values.end());
            std::cout << "{\"type\":\"JOB_RESULT\",\"jobId\":\"" << job_id << "\",\"output\":{\"sorted\":[";
            for (size_t i = 0; i < values.size(); ++i) {
                if (i != 0) {
                    std::cout << ",";
                }
                std::cout << values[i];
            }
            std::cout << "]}}" << std::endl;
        } else if (line.find("\"type\":\"SHUTDOWN\"") != std::string::npos) {
            break;
        }
    }
    return 0;
}
