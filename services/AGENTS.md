# Services - Kotlin Microservices

## OVERVIEW

Kotlin-based microservices communicating via NATS. Currently contains the Realm service.

## STRUCTURE

```
services/
├── build-logic/          # Shared Gradle conventions
├── libs/                 # Shared libraries
│   ├── service-registrar/    # Service registration helpers
│   └── service-communicator/ # NATS communication
├── realm/                # Realm service
└── libs.versions.toml    # Version catalog
```

## COMMANDS

```bash
./gradlew build           # Build all services
./gradlew :realm:run      # Run realm service
./gradlew test            # Run tests
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add new service | Create subproject, apply `basic-conventions` |
| Shared communication | `libs/service-communicator/` |
| Service registration | `libs/service-registrar/` |
| Version management | `libs.versions.toml` |

## CONVENTIONS

### Build
- Use `com.typewritermc.basic-conventions` plugin
- Versions in `libs.versions.toml`
- Kotlin 2.3.0, protokt for protobuf

### Dependencies
```kotlin
plugins {
    id("com.typewritermc.basic-conventions")
    application
}

dependencies {
    implementation("com.typewritermc:service-communicator")
    implementation("com.typewritermc:service-registrar")
}
```

### Code Style
Same as engine/extensions:
- 4 spaces, 120 char lines
- Guard clauses over nesting
- No inline comments

## NOTES

- Uses protokt (not standard protoc) for Kotlin proto generation
- NATS for messaging (same bus as Panel <-> Backend)
- Service discovery via registration to Backend identity service
