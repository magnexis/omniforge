open System
open System.Text.Json

let sendRaw (value: string) =
    Console.WriteLine(value)
    Console.Out.Flush()

let parseNumbers (root: JsonElement) =
    root.GetProperty("input").GetProperty("numbers").EnumerateArray()
    |> Seq.map (fun item -> item.GetDouble())
    |> Seq.toArray

[<EntryPoint>]
let main _ =
    let mutable line = Console.ReadLine()
    while not (isNull line) do
        use doc = JsonDocument.Parse(line)
        let root = doc.RootElement
        let messageType = root.GetProperty("type").GetString()
        match messageType with
        | "HELLO" ->
            sendRaw "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"fsharp-math-01\",\"language\":\"fsharp\",\"runtimeVersion\":\"net9.0\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"math.statistics\"}]}"
        | "JOB_START" ->
            let jobId = root.GetProperty("jobId").GetString()
            let capability = root.GetProperty("capability").GetString()
            if capability <> "math.statistics" then
                sendRaw (sprintf "{\"type\":\"JOB_ERROR\",\"jobId\":\"%s\",\"error\":\"unsupported capability\"}" jobId)
            else
                let numbers = parseNumbers root
                let total = numbers |> Array.sum
                let average = if numbers.Length = 0 then 0.0 else total / float numbers.Length
                sendRaw (sprintf "{\"type\":\"JOB_RESULT\",\"jobId\":\"%s\",\"output\":{\"count\":%d,\"total\":%.2f,\"average\":%.2f}}" jobId numbers.Length total average)
        | "SHUTDOWN" -> line <- null
        | _ -> ()
        if not (isNull line) then
            line <- Console.ReadLine()
    0
