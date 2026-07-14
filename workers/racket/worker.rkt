#lang racket
(require json)

(define (send msg)
  (displayln (jsexpr->string msg))
  (flush-output))

(for ([line (in-lines (current-input-port))])
  (define msg (string->jsexpr line))
  (define msg-type (hash-ref msg 'type ""))
  (cond
    [(equal? msg-type "HELLO")
     (send (hash 'type "WELCOME"
                 'protocol "ofp/1"
                 'workerId "racket-list-01"))
     (send (hash 'type "REGISTER"
                 'protocol "ofp/1"
                 'workerId "racket-list-01"
                 'language "racket"
                 'runtimeVersion "9.2"
                 'workerVersion "0.1.0"
                 'capabilities (list (hash 'name "data.aggregate"))))]
    [(equal? msg-type "REGISTER_ACK") (void)]
    [(equal? msg-type "JOB_START")
     (if (not (equal? (hash-ref msg 'capability "") "data.aggregate"))
         (send (hash 'type "JOB_ERROR" 'jobId "unknown" 'error "unsupported capability"))
         (let* ([job-id (hash-ref msg 'jobId "job-unknown")]
                [input (hash-ref msg 'input (hash))]
                [numbers (hash-ref input 'numbers '())]
                [total (apply + (map exact-round numbers))])
           (send (hash 'type "JOB_ACCEPTED" 'jobId job-id))
           (send (hash 'type "JOB_LOG" 'jobId job-id 'level "info" 'message "aggregating numeric input"))
           (send (hash 'type "JOB_RESULT"
                       'jobId job-id
                       'output (hash 'count (length numbers) 'sum total)))))]
    [(equal? msg-type "JOB_CANCEL")
     (send (hash 'type "JOB_CANCELLED" 'jobId (hash-ref msg 'jobId "job-unknown")))]
    [(equal? msg-type "SHUTDOWN")
     (send (hash 'type "SHUTDOWN_ACK" 'workerId "racket-list-01"))
     (exit 0)]))
