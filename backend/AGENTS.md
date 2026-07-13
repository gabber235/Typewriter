## NATS subject translation

- Panel → wasmCloud request: panel and permission code uses `cloud.to...`; backend subscriptions and handlers receive same flow as `typewriter.from...`.
- wasmCloud → panel event: backend publishers use `typewriter.to...`; panel listeners and subscribe permissions receive same flow as `cloud.from...`.
- Treat each pair as one logical flow. Choose prefix for side of bridge where code runs.
