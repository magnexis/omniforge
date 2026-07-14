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
     (send (hash 'type "REGISTER"
                 'protocol "ofp/1"
                 'workerId "scheme-product-01"
                 'language "scheme"
                 'runtimeVersion "racket-scheme"
                 'workerVersion "0.1.0"
                 'capabilities (list (hash 'name "math.product-scheme"))))]
    [(equal? msg-type "JOB_START")
     (if (not (equal? (hash-ref msg 'capability "") "math.product-scheme"))
         (send (hash 'type "JOB_ERROR" 'jobId "unknown" 'error "unsupported capability"))
         (let* ([job-id (hash-ref msg 'jobId "job-unknown")]
                [input (hash-ref msg 'input (hash))]
                [numbers (hash-ref input 'numbers '())]
                [product (if (null? numbers) 1 (apply * (map exact-round numbers)))])
           (send (hash 'type "JOB_RESULT"
                       'jobId job-id
                       'output (hash 'product product)))))]
    [(equal? msg-type "SHUTDOWN") (exit 0)]))
