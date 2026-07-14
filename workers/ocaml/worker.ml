let contains text pattern =
  let rec loop index =
    if index + String.length pattern > String.length text then false
    else if String.sub text index (String.length pattern) = pattern then true
    else loop (index + 1)
  in
  loop 0

let extract marker line =
  let marker_len = String.length marker in
  let rec loop index =
    if index + marker_len > String.length line then ""
    else if String.sub line index marker_len = marker then
      let start = index + marker_len in
      let stop = try String.index_from line start '"' with Not_found -> String.length line in
      String.sub line start (stop - start)
    else loop (index + 1)
  in
  loop 0

let extract_numbers line =
  let marker = "\"numbers\":[" in
  let marker_len = String.length marker in
  let rec loop index =
    if index + marker_len > String.length line then []
    else if String.sub line index marker_len = marker then
      let start = index + marker_len in
      let stop = try String.index_from line start ']' with Not_found -> start in
      let body = String.sub line start (stop - start) in
      if String.trim body = "" then []
      else body |> String.split_on_char ',' |> List.map (fun item -> int_of_string (String.trim item))
    else loop (index + 1)
  in
  loop 0

let () =
  try
    while true do
      let line = read_line () in
      if contains line "\"type\":\"HELLO\"" then
        print_endline "{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"ocaml-sum-01\",\"language\":\"ocaml\",\"runtimeVersion\":\"ocaml\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"math.sum-ocaml\"}]}"
      else if contains line "\"type\":\"JOB_START\"" then
        if contains line "\"capability\":\"math.sum-ocaml\"" then
          let job_id = extract "\"jobId\":\"" line in
          let sum = List.fold_left ( + ) 0 (extract_numbers line) in
          print_endline (Printf.sprintf "{\"type\":\"JOB_RESULT\",\"jobId\":\"%s\",\"output\":{\"sum\":%d}}" job_id sum)
        else
          print_endline "{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}"
    done
  with End_of_file -> ()
