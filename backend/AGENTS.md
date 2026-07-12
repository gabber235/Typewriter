## NATS subject translation

- Panel → wasmCloud request: panel and permission code uses `cloud.out...`; backend subscriptions and handlers receive same flow as `typewriter.in...`.
- wasmCloud → panel event: backend publishers use `typewriter.out...`; panel listeners and subscribe permissions receive same flow as `cloud.in...`.
- Treat each pair as one logical flow. Choose prefix for side of bridge where code runs.
