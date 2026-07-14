#!/usr/bin/env escript
%%! -noshell

main(_) ->
    loop().

loop() ->
    case io:get_line("") of
        eof -> ok;
        Line ->
            case string:find(Line, "\"type\":\"HELLO\"") of
                nomatch ->
                    case string:find(Line, "\"type\":\"REGISTER_ACK\"") of
                        nomatch ->
                            case string:find(Line, "\"type\":\"JOB_START\"") of
                                nomatch -> loop();
                                _ ->
                                    case string:find(Line, "\"capability\":\"system.ping\"") of
                                        nomatch ->
                                            io:format("{\"type\":\"JOB_ERROR\",\"jobId\":\"unknown\",\"error\":\"unsupported capability\"}~n"),
                                            loop();
                                        _ ->
                                            Job = extract(Line, "\"jobId\":\""),
                                            io:format("{\"type\":\"JOB_ACCEPTED\",\"jobId\":\"~s\"}~n", [Job]),
                                            io:format("{\"type\":\"JOB_LOG\",\"jobId\":\"~s\",\"level\":\"info\",\"message\":\"responding with pong\"}~n", [Job]),
                                            io:format("{\"type\":\"JOB_RESULT\",\"jobId\":\"~s\",\"output\":{\"pong\":true}}~n", [Job]),
                                            loop()
                                    end
                            end;
                        _ ->
                            case string:find(Line, "\"type\":\"JOB_CANCEL\"") of
                                nomatch ->
                                    case string:find(Line, "\"type\":\"SHUTDOWN\"") of
                                        nomatch -> loop();
                                        _ ->
                                            io:format("{\"type\":\"SHUTDOWN_ACK\",\"workerId\":\"erlang-presence-01\"}~n"),
                                            ok
                                    end;
                                _ ->
                                    Job = extract(Line, "\"jobId\":\""),
                                    io:format("{\"type\":\"JOB_CANCELLED\",\"jobId\":\"~s\"}~n", [Job]),
                                    loop()
                            end
                    end;
                _ ->
                    io:format("{\"type\":\"WELCOME\",\"protocol\":\"ofp/1\",\"workerId\":\"erlang-presence-01\"}~n"),
                    io:format("{\"type\":\"REGISTER\",\"protocol\":\"ofp/1\",\"workerId\":\"erlang-presence-01\",\"language\":\"erlang\",\"runtimeVersion\":\"otp-29\",\"workerVersion\":\"0.1.0\",\"capabilities\":[{\"name\":\"system.ping\"}]}~n"),
                    loop()
            end
    end.

extract(Line, Marker) ->
    case string:find(Line, Marker) of
        nomatch -> "job-unknown";
        Rest ->
            Content = string:slice(Rest, length(Marker)),
            Pieces = string:split(Content, "\"", all),
            hd(Pieces)
    end.
