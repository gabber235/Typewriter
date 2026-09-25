# Skir Contracts

This directory contains the canonical Typewriter contracts. Design these files around durable product concepts, not as mirrors of current transport routes, database tables, or generated code.

## Directory Structure

Only use these top-level folders:

- `kernel`
- `access`
- `organization`
- `service`
- `library`
- `editor`

Each bounded context owns its own version folders, such as `library/v1` or `service/v1`. These folders do not imply a stability promise before release.

## Core Design Rules

- Model Typewriter business concepts first. NATS subjects, HTTP paths, storage layout, and generated-code details belong in adapters, not in the core contract shape.
- Use resource models for state and command models for mutation. Reads return durable resources; writes express intent such as create, rename, move, resize, link, replace, or update a field.
- Keep read models and write models separate. Display-oriented shapes are often not safe mutation shapes.
- Define full models only when consumers genuinely need them. Prefer summaries, references, commands, and focused result payloads for narrower workflows.
- Separate query, command, and event surfaces. Queries read state, commands change state, and events describe completed state changes.
- Model failures as typed outcomes, not string errors. Use result variants such as success, validation_failed, not_found, permission_denied, and conflict.
- Do not model database internals. Contracts should survive database rewrites and must not be shaped around record layouts, indexes, storage-specific IDs, or query details.

## Pre-release evolution

- Typewriter has not been released. Make breaking contract changes directly in the existing `v1` folders when they improve the model, and update all consumers together.
- Do not increment contract versions or revisions, or preserve unreleased shapes with migrations, compatibility aliases, deprecation stages, or parallel version folders.
- Keep declaration IDs and field or variant numbers contiguous and ascending within their respective sequences. Renumber after changes instead of reserving gaps for compatibility.
- Define compatibility and versioning guarantees when a contract is actually published as stable.
