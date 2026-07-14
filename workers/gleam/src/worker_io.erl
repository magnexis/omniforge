-module(worker_io).
-export([read_line/0]).

read_line() ->
    case io:get_line("") of
        eof -> "eof";
        Line -> Line
    end.
