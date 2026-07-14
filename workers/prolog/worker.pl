:- use_module(library(http/json)).
:- use_module(library(readutil)).
:- initialization(main).

classify(Score, premium) :- Score >= 90, !.
classify(Score, standard) :- Score >= 60, !.
classify(_, basic).

incident_policy(Incident, Severity, Action) :-
    CPU is Incident.get(cpu),
    Memory is Incident.get(memory),
    Restarts is Incident.get(restarts),
    ErrorRate is Incident.get(error_rate),
    (   ( CPU >= 95 ; Memory >= 95 ; ErrorRate >= 0.20 )
    ->  Severity = critical,
        Action = isolate_host
    ;   ( CPU >= 85 ; Memory >= 85 ; Restarts >= 3 ; ErrorRate >= 0.10 )
    ->  Severity = high,
        Action = restart_service
    ;   Severity = medium,
        Action = recycle_worker
    ).

annotate_incident(Incident, Output) :-
    incident_policy(Incident, Severity, Action),
    Output = Incident.put(_{
        severity: Severity,
        action: Action
    }).

count_severity([], _, 0).
count_severity([Incident|Rest], Severity, Count) :-
    count_severity(Rest, Severity, TailCount),
    ( Incident.get(severity) = Severity ->
        Count is TailCount + 1
    ; Count = TailCount
    ).

send_register :-
    writeln('{"type":"REGISTER","protocol":"ofp/1","workerId":"prolog-rules-01","language":"prolog","runtimeVersion":"swi-prolog","workerVersion":"0.1.0","capabilities":[{"name":"rules.classify"},{"name":"ops.policy-evaluate"}]}'),
    flush_output.

send_welcome :-
    writeln('{"type":"WELCOME","protocol":"ofp/1","workerId":"prolog-rules-01"}'),
    flush_output.

send_job_accepted(JobId) :-
    format('{"type":"JOB_ACCEPTED","jobId":"~w"}~n', [JobId]),
    flush_output.

send_job_log(JobId, Message) :-
    format('{"type":"JOB_LOG","jobId":"~w","level":"info","message":"~w"}~n', [JobId, Message]),
    flush_output.

send_result(JobId, Tier, Score) :-
    format('{"type":"JOB_RESULT","jobId":"~w","output":{"tier":"~w","score":~w}}~n', [JobId, Tier, Score]),
    flush_output.

send_error(JobId, Error) :-
    format('{"type":"JOB_ERROR","jobId":"~w","error":"~w"}~n', [JobId, Error]),
    flush_output.

send_ops_result(JobId, Incidents, CriticalCount, HighCount, MediumCount) :-
    Result = _{
        type: "JOB_RESULT",
        jobId: JobId,
        output: _{
            incidents: Incidents,
            summary: _{
                critical: CriticalCount,
                high: HighCount,
                medium: MediumCount
            }
        }
    },
    atom_json_dict(Atom, Result, []),
    writeln(Atom),
    flush_output.

send_cancelled(JobId) :-
    format('{"type":"JOB_CANCELLED","jobId":"~w"}~n', [JobId]),
    flush_output.

send_shutdown_ack :-
    writeln('{"type":"SHUTDOWN_ACK","workerId":"prolog-rules-01"}'),
    flush_output.

handle_message(Message) :-
    Type = Message.get(type),
    ( Type = "HELLO" ->
        send_welcome,
        send_register
    ; Type = "REGISTER_ACK" ->
        true
    ; Type = "JOB_START" ->
        Capability = Message.get(capability),
        JobId = Message.get(jobId),
        send_job_accepted(JobId),
        ( Capability = "rules.classify" ->
            Input = Message.get(input),
            Score = Input.get(score),
            send_job_log(JobId, classify_score),
            classify(Score, Tier),
            send_result(JobId, Tier, Score)
        ; Capability = "ops.policy-evaluate" ->
            Input = Message.get(input),
            Previous = Input.get(previous),
            Incidents = Previous.get(incidents),
            send_job_log(JobId, evaluate_incidents),
            maplist(annotate_incident, Incidents, Annotated),
            count_severity(Annotated, critical, CriticalCount),
            count_severity(Annotated, high, HighCount),
            count_severity(Annotated, medium, MediumCount),
            send_ops_result(JobId, Annotated, CriticalCount, HighCount, MediumCount)
        ; send_error(JobId, "unsupported capability")
        )
    ; Type = "JOB_CANCEL" ->
        JobId = Message.get(jobId),
        send_cancelled(JobId)
    ; true
    ).

loop :-
    read_line_to_string(user_input, Line),
    ( Line == end_of_file ->
        true
    ; atom_json_dict(Line, Message, []),
      ( Message.get(type) = "SHUTDOWN" ->
            send_shutdown_ack,
            halt(0)
      ; handle_message(Message),
        loop
      )
    ).

main :- loop.
