sub send($message) {
  say $message;
  $*OUT.flush;
}

sub extract($line, $marker) {
  my $start = $line.index($marker);
  return "" unless $start.defined;
  my $rest = $line.substr($start + $marker.chars);
  my $stop = $rest.index('"');
  return "" unless $stop.defined;
  $rest.substr(0, $stop);
}

for lines() -> $line {
  if $line.contains('"type":"HELLO"') {
    send('{"type":"WELCOME","protocol":"ofp/1","workerId":"raku-title-01","language":"raku","runtimeVersion":"26.6.1","workerVersion":"0.1.0","status":"ready"}');
    send('{"type":"REGISTER","protocol":"ofp/1","workerId":"raku-title-01","language":"raku","runtimeVersion":"26.6.1","workerVersion":"0.1.0","capabilities":[{"name":"text.title-case"}]}');
  } elsif $line.contains('"type":"REGISTER_ACK"') {
    next;
  } elsif $line.contains('"type":"JOB_START"') {
    if !$line.contains('"capability":"text.title-case"') {
      send('{"type":"JOB_ERROR","jobId":"unknown","error":"unsupported capability"}');
    } else {
      my $job = extract($line, '"jobId":"');
      $job = "job-unknown" if $job eq "";
      my $text = extract($line, '"text":"');
      my $title = $text.tc;
      send('{"type":"JOB_ACCEPTED","jobId":"' ~ $job ~ '","status":"running"}');
      send('{"type":"JOB_LOG","jobId":"' ~ $job ~ '","severity":"info","message":"starting text.title-case"}');
      send('{"type":"JOB_RESULT","jobId":"' ~ $job ~ '","output":{"title":"' ~ $title ~ '"}}');
    }
  } elsif $line.contains('"type":"JOB_CANCEL"') {
    my $job = extract($line, '"jobId":"');
    $job = "job-unknown" if $job eq "";
    send('{"type":"JOB_CANCELLED","jobId":"' ~ $job ~ '","status":"cancelled"}');
  } elsif $line.contains('"type":"SHUTDOWN"') {
    send('{"type":"SHUTDOWN_ACK","workerId":"raku-title-01","status":"stopped"}');
    exit 0;
  }
}
