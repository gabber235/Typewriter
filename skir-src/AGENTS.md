# Skir Contracts

This directory contains the canonical Typewriter contracts. Design these files as long-lived product promises between components, not as mirrors of current transport routes, database tables, or generated code.

## Directory Structure

Only use these top-level folders:

- `kernel`
- `access`
- `organization`
- `service`
- `library`
- `editor`

Each bounded context owns its own version folders, such as `library/v1` or `service/v2`.

## Core Design Rules

- Model Typewriter business concepts first. NATS subjects, HTTP paths, storage layout, and generated-code details belong in adapters, not in the core contract shape.
- Use resource models for state and command models for mutation. Reads return durable resources; writes express intent such as create, rename, move, resize, link, replace, or update a field.
- Keep read models and write models separate. Display-oriented shapes are often not safe mutation shapes.
- Define full models only when consumers genuinely need them. Prefer summaries, references, commands, and focused result payloads for narrower workflows.
- Separate query, command, and event surfaces. Queries read state, commands change state, and events describe completed state changes.
- Model failures as typed outcomes, not string errors. Use result variants such as success, validation_failed, not_found, permission_denied, and conflict.
- Do not model database internals. Contracts should survive database rewrites and must not be shaped around record layouts, indexes, storage-specific IDs, or query details.

## Compatibility

- Make every compatibility promise explicit. Mark contracts as experimental, internal, or stable.
- Stable contracts are additive-only within the same major version.
- Prefer additive evolution: add fields, variants, methods, or events.
- Do not change field meaning, change defaults, narrow accepted input, or make optional data required inside a stable major version.
- Use deprecation before removal. Stable fields, methods, and events should move through deprecated, unsupported, and removed in the next major version instead of disappearing suddenly.

## Versioning

- Stable contract packages use major-versioned folders, such as `v1` and `v2`.
- Breaking changes require a new major version folder. Keep the old version available during migration.
- Version by bounded context instead of forcing one global project version. For example, a breaking change in `library/v1` creates `library/v2` and does not force `organization/v2`.
- Prefer adding new operations inside an existing major version when the old operation can remain correct.
