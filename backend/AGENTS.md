## NATS subject translation

- Panel → wasmCloud request: panel and permission code uses `cloud.to...`; backend subscriptions and handlers receive same flow as `typewriter.from...`.
- wasmCloud → panel event: backend publishers use `typewriter.to...`; panel listeners and subscribe permissions receive same flow as `cloud.from...`.
- Treat each pair as one logical flow. Choose prefix for side of bridge where code runs.

## SurrealDB query design

- Bind complete record identifiers as `surrealdb_component_sdk::RecordId` values. Do not pass record keys and reconstruct records with `type::record` inside SurrealQL.
- In backend components, validate only that incoming record identifiers belong to the expected tables. Keep domain validation and mutation logic in one SurrealQL transaction whenever possible.
- Prefer one cohesive database query over multiple small queries with coordinating Rust logic. Extra database round trips and application side coordination are slower and can weaken transactional guarantees.
- Use `skir_domain_result!` when a transaction uses `THROW` to return a domain slug without database computed payload data.
- Use a Serde internally tagged outcome enum with `skir_transaction_outcome!` when a transaction returns precise database computed success or error payloads.
