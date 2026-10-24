## Macros and code generation

Prefer Rust macros when they make declarations and calling code more readable, remove boilerplate, or improve developer experience. Use macros to express repeated patterns and domain declarations concisely, with useful validation during compilation.

Reuse and extend the existing macros exposed through `wasmcloud_utils`, including query declarations, response construction, and identifier validation. Response outcome classification is generated from Skir variant names; do not register it by hand. Shared procedural macros live in `wasmcloud-utils-macros`. Choose `macro_rules!`, derives, or procedural macros according to the transformation required.

Keep macro inputs expressive and expansions deterministic and inspectable. Make generated types, control flow, ownership, and effects understandable from the declaration. Report invalid inputs with actionable compiler errors at the relevant source location. Use ordinary functions and traits for shared behavior when they provide an equally clear API with less machinery.

When changing macros, update affected callers and verify representative expansions compile. Use the existing macro tests to cover meaningful behavior and diagnostics for invalid declarations.

## NATS subject translation

- Panel → wasmCloud request: panel and permission code uses `cloud.to...`; backend subscriptions and handlers receive same flow as `typewriter.from...`.
- wasmCloud → panel event: backend publishers use `typewriter.to...`; panel listeners and subscribe permissions receive same flow as `cloud.from...`.
- `services/protocol/transport-routes.yaml` declares each flow once (a role caller and a component server); the generator derives both prefixes. Do not write bridged subjects by hand.

## SurrealDB query design

- Bind complete record identifiers as `surrealdb_component_sdk::RecordId` values. Do not pass record keys and reconstruct records with `type::record` inside SurrealQL.
- In backend components, validate only that incoming record identifiers belong to the expected tables. Keep domain validation and mutation logic in one SurrealQL transaction whenever possible.
- Prefer one cohesive database query over multiple small queries with coordinating Rust logic. Extra database round trips and application side coordination are slower and can weaken transactional guarantees.
- Use `skir_domain_result!` when a transaction uses `THROW` to return a domain slug without database computed payload data.
- Use a Serde internally tagged outcome enum with `skir_transaction_outcome!` when a transaction returns precise database computed success or error payloads.
- Execute every mutation through `wasmcloud_utils::database::retrying_transaction` with explicit `BEGIN TRANSACTION` and `COMMIT TRANSACTION` boundaries.
