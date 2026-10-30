# Importer and migrator

## What it is

Two tools that move data forward. They solve different problems and run at different times.

| | Importer | Migrator |
| --- | --- | --- |
| Moves | Legacy Typewriter (0.9) content and data into 1.0 | Data between **revisions** of a Typewriter type |
| Runs | **Once** per host, then never again | Whenever an extension or core ships a new type revision |
| Starts | Automatically: it detects that a host has legacy data and requests it | Automatically on update |
| Written by | Typewriter | The developer of the type (core or extension) |

### Importer

- Detects legacy data on a host and asks to import it into 1.0.
- A one time path: after the import it no longer runs for anybody.
- How detection and the request work is decided during the closed beta.

### Migrator

- Every persisted value is a **Typewriter type** with a numbered **revision**: entry data, configuration data, and stored data. Stored value types are Typewriter types too, because they are written to the database.
- Between two revisions, the developer of the type specifies how old data becomes new data.
- Content changes use the same mechanism: when a creator changes a shape (a variable's type or keys, a removed quest stage), the type's migration asks for any needed input as ordinary fields and runs at publication (see [data-storage.md](data-storage.md)).

## Who it serves

Server owners upgrading from legacy Typewriter, and extension developers who change their types without breaking existing servers.

## Why

Legacy servers need a way in. After release, extensions and core must be able to evolve their types without losing player progress or content.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Importer for 0.9 content and data, one time, auto detected | closed beta | sketch |
| Migrator between type revisions (stored, entry, configuration data) | closed beta (early, not the first version) | shaped |

## Open questions

- How the importer detects legacy data and requests it.
- How a developer writes a migration step between revisions.
