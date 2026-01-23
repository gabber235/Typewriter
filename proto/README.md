# Typewriter Protocol Buffers

This directory contains all Protocol Buffer definitions for Typewriter's panel and backend communication.

## Structure

- `models/` - Domain models (Organization, Manual, Book, etc.)
- `api/` - Request/response messages for NATS subjects

## Conventions

### Naming
- Use `snake_case` for field names
- Use `PascalCase` for message and enum names
- Prefix enums with their type name (e.g., `PAGE_TYPE_STATIC`)
- Always include `_UNSPECIFIED = 0` as first enum value

### Packages
- Models: `typewriter.models.v1`
- API: `typewriter.api.v1`

## Code Generation

Each component generates its own code from these proto files:

### Panel (Dart)
```bash
cd panel
make proto
```

### Backend (Rust)
Code generation happens automatically via `build.rs` during `cargo build`.

## Adding New Messages

1. Create or modify proto files in `models/` or `api/`
2. Regenerate code in panel: `cd panel && make proto`
3. Backend regenerates automatically on next build
4. Update code that uses the messages
