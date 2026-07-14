\ Minimal OFP worker for Gforth.

: contains? ( c-addr u pat-addr pat-u -- flag )
  search nip nip ;

: send-register ( -- )
  s\" {\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"forth-max-01\",\"language\":\"forth\",\"runtimeVersion\":\"gforth-0.7.0\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"math.max\"}]}" type cr ;

: send-error ( -- )
  s\" {\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}" type cr ;

: send-result ( n -- )
  >r
  s\" {\"type\":\"JOB_RESULT\",\"jobId\":\"job-1" type
  s\" \",\"output\":{\"max\":" type
  r> 0 <# #s #> type
  s\" }}" type cr ;

create linebuf 4096 chars allot
variable max-value
variable current-value
variable in-number

: reset-parser ( -- )
  0 max-value !
  0 current-value !
  0 in-number ! ;

: flush-number ( -- )
  in-number @ if
    current-value @ max-value @ > if
      current-value @ max-value !
    then
    0 current-value !
    0 in-number !
  then ;

: parse-max ( c-addr u -- n )
  reset-parser
  bounds ?do
    i c@ dup [char] 0 >= over [char] 9 <= and if
      [char] 0 - current-value @ 10 * + current-value !
      -1 in-number !
    else
      drop flush-number
    then
  loop
  flush-number
  max-value @ ;

: handle-line ( c-addr u -- continue? )
  2dup s\" \"type\":\"HELLO\"" contains? if
    2drop send-register true exit
  then
  2dup s\" \"type\":\"JOB_START\"" contains? if
    2dup s\" \"capability\":\"math.max\"" contains? 0= if
      2drop send-error true exit
    then
    parse-max
    send-result
    false exit
  then
  2dup s\" \"type\":\"SHUTDOWN\"" contains? if
    2drop false exit
  then
  2drop true ;

: main
  begin
    linebuf 4096 stdin read-line throw
  while
    linebuf swap handle-line 0= if bye then
  repeat bye ;

main
