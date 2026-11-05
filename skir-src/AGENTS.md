# Skir Contracts

This directory contains the canonical Typewriter contracts. Design these files around durable product concepts, not as mirrors of current transport routes, database tables, or generated code.

## Directory Structure

Only use these top-level folders:

- `kernel`
- `access`
- `organization`
- `service`
- `editor`
- `harness` (results the test runners write and `cargo xtask` reads, not product concepts)

Each bounded context owns its own version folders, such as `editor/v1` or `service/v1`. These folders do not imply a stability promise before release.

## Core Design Rules

- Model Typewriter business concepts first. NATS subjects, HTTP paths, storage layout, and generated-code details belong in adapters, not in the core contract shape.
- Use resource models for state and command models for mutation. Reads return durable resources; writes express intent such as create, rename, move, resize, link, replace, or update a field.
- Keep read models and write models separate. Display-oriented shapes are often not safe mutation shapes.
- Define full models only when consumers genuinely need them. Prefer summaries, references, commands, and focused result payloads for narrower workflows.
- Separate query, command, and event surfaces. Queries read state, commands change state, and events describe completed state changes.
- Model failures as typed outcomes, not string errors. Name every failure variant with an `_error` suffix (validation_error, not_found_error, permission_denied_error, conflict_error); any other variant is a success. Every request response is an enum with `internal_error: InternalError`. The repository Skir generator (`services/protocol/skir-gen`) derives outcome classification from these names.
- Describe complete results. Never model transport framing such as chunks, transfer identities or size limits; the transport splits large requests and responses.
- Do not model database internals. Contracts should survive database rewrites and must not be shaped around record layouts, indexes, storage-specific IDs, or query details.

## Contract boundary

`skir-src` holds every value that crosses a process or language boundary between independently
running parties (panel, backend components, services, Realm, hosts), and the portable data that
Kotlin and Dart both interpret (expressions, presentations, catalogs). Kotlin, Dart and Rust use
the generated types directly.

### Imports between contexts

- A context imports only its own files and `kernel`. `kernel` imports nothing.
- `kernel` holds identities (`RecordId`, `ResourceId`), primitive values (`Color`, `Duration`,
  `Icon`) and failure markers (`InternalError`, `InvalidRecordIdError`). Add to it only when a
  second context needs the same value.
- Contexts refer to each other's entities by a kernel identity, never by importing another
  context's declarations.

### Host API mirrors

A hand written type that mirrors a contract is allowed only when all three hold:

1. It belongs to an in-process API with its own compatibility promise: the loader host API
   (`services/runtime/loader/api`, `hostApi = "^1"`) or the extension SDK (`typewriter-api`,
   `typewriter-contracts`).
2. It adds something the generated type cannot: invariants, an idiomatic Kotlin shape, or a
   host storage format.
3. One translation file per boundary converts both ways, and decoding goes through the
   mirror's constructors (`loader/artifact/ArtifactWire.kt`).

Never mirror inside one deployable just to avoid importing `skirout`. Backend database row
structs are storage adapters, not mirrors.

### Known exception

- `kernel/v1/record_id.skir`: `RecordId` keeps SurrealDB's key shapes (number, uuid, array,
  object) although every producer uses a string key.

### Numbering

Every struct, enum and method number is derived from where it is declared:

| Kind        | Number       | Example                                   |
|-------------|--------------|-------------------------------------------|
| declaration | `8 C FF NNNN` | `editor/v1/catalog.skir` (file 06), 1st struct: `84060001` |
| method      | `9 C FF NN`   | same file, 1st method: `940601`|

`C` is the context (kernel 0, access 1, organization 2, service 3, editor 4, harness 5), `FF` the file's
position in its `v1` folder in byte order of the file name from 01, `NNNN` and `NN` the position in
the file from 1. Write a new method with `= ?` (Skir requires the `=`) and a new type without a
number; `cargo xtask generate` writes the numbers, rewrites stale ones and rejects forbidden
imports. Never pick a number by hand. Variants run 1, 2, 3 and `removed` is not used before release.

## Pre-release evolution

- Typewriter has not been released. Make breaking contract changes directly in the existing `v1` folders when they improve the model, and update all consumers together.
- Do not increment contract versions or revisions, or preserve unreleased shapes with migrations, compatibility aliases, deprecation stages, or parallel version folders.
- Keep declaration IDs and field or variant numbers contiguous and ascending within their respective sequences. Renumber after changes instead of reserving gaps for compatibility.
- Declaration and method numbers are derived; see Contract boundary, Numbering.
- Define compatibility and versioning guarantees when a contract is actually published as stable.

## Portable expression operations

`editor/v1/operations.yaml` declares every primitive of the portable expression language: signature, profile, failures and item identities. Expressions call them through `ExpressionNode.call`; `expression.skir` does not change for a new operation.

- Prefer a Kotlin shortcut (`services/sdk/typewriter-api/.../expression/shortcuts/`) over a new primitive. A primitive is only justified when no composition of primitives gives the same result (missing data, failures and list item identities included) without asymptotically more work or a lost early exit.
- Adding a primitive: declare it, run `cargo xtask generate`, implement the generated Kotlin kernel method (profile `rule` only) and the Dart kernel method, then add cases to `editor/v1/fixtures/operations/<group>.json`. The compilers and the coverage test point at each missing step.
- Profile `panel` operations (localized formatting, time zones, resource reads) have no Kotlin kernel; rules and selection predicates cannot use them.
- Failures are declared in the manifest and travel as `FailureId`; never raise or compare string codes.
