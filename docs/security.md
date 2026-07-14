# Security Notes

Omniforge executes multiple runtimes and treats workers as failure boundaries.

## Implemented

- coordinator and workers run as separate processes
- workers only communicate through OFP messages over stdio
- capabilities are explicitly declared
- unsupported capabilities return structured errors

## Planned

- hard execution timeouts
- memory and CPU limits
- filesystem isolation
- worker authentication
- container-based language packs
- stronger validation for input and artifact size
