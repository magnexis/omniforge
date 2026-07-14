function worker()
  while (true)
    line = fgetl(stdin);
    if (!ischar(line))
      break;
    endif

    if (!isempty(strfind(line, '"type":"HELLO"')))
      send_message('{"type":"REGISTER","protocol":"ofp/1","workerId":"octave-mean-01","language":"octave","runtimeVersion":"11.3.0","workerVersion":"0.1.0","capabilities":[{"name":"math.mean"}]}');
    elseif (!isempty(strfind(line, '"type":"JOB_START"')))
      if (isempty(strfind(line, '"capability":"math.mean"')))
        send_message('{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}');
      else
        job_id = extract_value(line, '"jobId":"');
        if (isempty(job_id))
          job_id = 'job-unknown';
        endif
        values = extract_numbers(line);
        count = numel(values);
        avg = 0;
        if (count > 0)
          avg = mean(values);
        endif
        send_message(sprintf('{"type":"JOB_RESULT","jobId":"%s","output":{"count":%d,"mean":%g}}', job_id, count, avg));
      endif
    elseif (!isempty(strfind(line, '"type":"SHUTDOWN"')))
      break;
    endif
  endwhile
endfunction

function value = extract_value(line, marker)
  value = '';
  start_pos = strfind(line, marker);
  if (isempty(start_pos))
    return;
  endif

  from = start_pos(1) + length(marker);
  if (from > length(line))
    return;
  endif

  rest = line(from:end);
  stop_pos = strfind(rest, '"');
  if (isempty(stop_pos))
    return;
  endif

  value = rest(1:(stop_pos(1) - 1));
endfunction

function values = extract_numbers(line)
  values = [];
  marker = '"numbers":[';
  start_pos = strfind(line, marker);
  if (isempty(start_pos))
    return;
  endif

  from = start_pos(1) + length(marker);
  if (from > length(line))
    return;
  endif

  rest = line(from:end);
  end_pos = strfind(rest, ']');
  if (isempty(end_pos))
    return;
  endif

  body = rest(1:(end_pos(1) - 1));
  if (isempty(body))
    return;
  endif

  parts = strsplit(body, ',');
  for i = 1:numel(parts)
    piece = strtrim(parts{i});
    if (!isempty(piece))
      values(end + 1) = str2double(piece);
    endif
  endfor
endfunction

function send_message(text)
  fprintf('%s\n', text);
  fflush(stdout);
endfunction

worker();
