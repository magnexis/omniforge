(require '[cheshire.core :as json])

(defn send! [payload]
  (println (json/generate-string payload))
  (flush))

(defn handle-line [line]
  (let [message (json/parse-string line true)
        type (:type message)]
    (case type
      "HELLO"
      (send! {:type "REGISTER"
              :protocol "ofp/1"
              :workerId "clojure-frequencies-01"
              :language "clojure"
              :runtimeVersion "babashka"
              :workerVersion "0.1.0"
              :capabilities [{:name "data.frequencies"}]})

      "JOB_START"
      (if (= "data.frequencies" (:capability message))
        (let [items (vec (get-in message [:input :items] []))
              counts (frequencies items)]
          (send! {:type "JOB_RESULT"
                  :jobId (:jobId message)
                  :output {:count (count items)
                           :uniqueCount (count counts)
                           :frequencies counts}}))
        (send! {:type "JOB_ERROR"
                :jobId (:jobId message)
                :error "unsupported capability"}))

      "SHUTDOWN"
      (System/exit 0)

      nil)))

(doseq [line (line-seq (java.io.BufferedReader. *in*))]
  (when (seq line)
    (handle-line line)))
