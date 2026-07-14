using System.Diagnostics;
using System.Text.Json;

static void Send(object payload)
{
    Console.WriteLine(JsonSerializer.Serialize(payload));
}

string? line;
while ((line = Console.ReadLine()) is not null)
{
    using var document = JsonDocument.Parse(line);
    var root = document.RootElement;
    var type = root.GetProperty("type").GetString();

    if (type == "HELLO")
    {
        Send(new
        {
            type = "REGISTER",
            protocol = "ofp/1",
            workerId = "csharp-process-01",
            language = "csharp",
            runtimeVersion = Environment.Version.ToString(),
            workerVersion = "0.1.0",
            capabilities = new[] { new { name = "system.process-info" } }
        });
    }
    else if (type == "JOB_START")
    {
        var capability = root.GetProperty("capability").GetString();
        var jobId = root.GetProperty("jobId").GetString();
        if (capability != "system.process-info")
        {
            Send(new { type = "JOB_ERROR", jobId, error = "unsupported capability" });
            continue;
        }

        var current = Process.GetCurrentProcess();
        Send(new
        {
            type = "JOB_RESULT",
            jobId,
            output = new
            {
                processId = current.Id,
                processName = current.ProcessName,
                workingSetBytes = current.WorkingSet64
            }
        });
    }
    else if (type == "SHUTDOWN")
    {
        break;
    }
}
