# Proto: Shared Protobuf Contracts

## OVERVIEW

Single source of truth for all communication contracts between Panel, Backend, and Services.

## STRUCTURE

```
proto/
├── api/                  # NATS subject definitions (request/response)
│   ├── auth.proto
│   ├── service.proto
│   ├── book.proto
│   ├── page.proto
│   ├── user/
│   │   └── organization.proto
│   └── organization/
│       ├── member.proto
│       └── role.proto
└── models/               # Domain models (shared types)
    ├── common.proto      # Color, Error
    ├── auth.proto
    ├── service.proto
    ├── book.proto
    ├── organization.proto
    └── organization/
        ├── member.proto
        └── role.proto
```

## CONVENTIONS

### Naming
- Messages: `PascalCase`
- Fields: `snake_case`
- Packages: `typewriter.models.v1`, `typewriter.api.v1`

### Enums
```protobuf
enum MyEnum {
  MY_ENUM_UNSPECIFIED = 0;  // Always first, prefixed with type name
  MY_ENUM_VALUE_ONE = 1;
  MY_ENUM_VALUE_TWO = 2;
}
```

### Field Numbers
- 1-15: Frequently used fields (1 byte)
- 16-2047: Less frequent (2 bytes)
- Reserve numbers when removing fields

## REGENERATION

After changing `.proto` files:

```bash
# Panel (Dart)
cd panel && task proto

# Backend (Rust)
# Automatic via build.rs on `cargo build`

# Services (Kotlin)
# Automatic via protokt on `./gradlew build`
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add domain model | `models/` |
| Add API endpoint | `api/` |
| Common types | `models/common.proto` |
| Auth types | `models/auth.proto` + `api/auth.proto` |
| Organization types | `models/organization/` + `api/organization/` |

## ANTI-PATTERNS

| Pattern | Alternative |
|---------|-------------|
| Enum without `_UNSPECIFIED = 0` | Always add unspecified as first value |
| `camelCase` fields | Use `snake_case` |
| Forgetting regeneration | Run proto tasks after changes |
| Removing field numbers | Reserve them instead |

## NOTES

- API protos define NATS subjects for request/response
- Models protos define reusable types
- Breaking changes require versioning (new package `v2`)
