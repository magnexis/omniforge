defmodule Worker do
  def run do
    IO.stream(:stdio, :line)
    |> Enum.each(&handle_line(String.trim(&1)))
  end

  defp handle_line(line) do
    cond do
      String.contains?(line, ~s("type":"HELLO")) ->
        IO.puts(~s({"type":"REGISTER","protocol":"ofp/1","workerId":"elixir-upper-01","language":"elixir","runtimeVersion":"elixir","workerVersion":"0.1.0","capabilities":[{"name":"text.uppercase-ex"}]}))

      String.contains?(line, ~s("type":"JOB_START")) ->
        if String.contains?(line, ~s("capability":"text.uppercase-ex")) do
          job_id = extract(line, ~s("jobId":""))
          text = extract(line, ~s("text":""))
          IO.puts(~s({"type":"JOB_RESULT","jobId":"#{job_id}","output":{"uppercased":"#{String.upcase(text)}"}}))
        else
          IO.puts(~s({"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}))
        end

      true ->
        :ok
    end
  end

  defp extract(line, marker) do
    case String.split(line, marker, parts: 2) do
      [_, rest] ->
        rest
        |> String.split("\"", parts: 2)
        |> List.first()

      _ ->
        ""
    end
  end
end

Worker.run()
