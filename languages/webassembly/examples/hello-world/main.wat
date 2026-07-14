(module
  (import "env" "log" (func $log))
  (func (export "main") call $log)
)
