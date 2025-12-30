# Backend - Rust/wasmCloud Services

## OVERVIEW

Microservices for auth, identity, and organization management. Built with Rust + wasmCloud, deployed to Kubernetes.

## STRUCTURE

```
backend/
├── auth/
│   ├── auth-callout/              # NATS auth callout handler
│   └── auth-typewriter-permissions/  # Permission resolution
├── organization/
│   ├── members/                   # Organization membership CRUD
│   └── roles/                     # Role management
├── service/
│   └── identity/                  # Service identity registration
├── user/
│   └── organizations/             # User's organization operations
├── providers/
│   └── surrealdb/                 # SurrealDB capability provider
├── database/
│   └── database.surql             # SurrealDB schema
├── tests/                         # Integration tests
├── wasmcloud-utils/               # Shared wasmCloud utilities
├── Taskfile.yml                   # Orchestration
└── Taskfile.single.yml            # Shared task template
```

## COMMANDS

```bash
task build:all                # Build all components (wash build)
task push:all                 # Push to OCI registry
task deploy:all               # Deploy all components
task setup:all                # Build + push + deploy
task test                     # Run integration tests
task list                     # Show all sub-Taskfiles
```

Per-component (from component directory):
```bash
task build                    # wash build
task push                     # Push to registry
task deploy                   # Deploy component
task status                   # Check deployment status
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add new service | Create dir, copy `Taskfile.yml` from existing |
| Modify auth flow | `auth/auth-callout/` |
| Add org endpoint | `organization/` |
| Add user endpoint | `user/` |
| Database schema | `database/database.surql` |
| Integration tests | `tests/` |

## CONVENTIONS

### wasmCloud Components
- Each component has `wasmcloud.toml` config
- Use `wit-bindgen` for interface definitions
- Inherit from `Taskfile.single.yml` for consistent tasks

### Database
- SurrealDB with schema in `database/database.surql`
- Use the `surrealdb` capability provider

### Task Inheritance
```yaml
# In component's Taskfile.yml:
version: "3"
includes:
  single:
    taskfile: ../Taskfile.single.yml
    flatten: true
vars:
  COMPONENT_NAME: my-service
```

## ANTI-PATTERNS

| Pattern | Alternative |
|---------|-------------|
| Direct registry calls | Use `task push` |
| Manual wash commands | Use Taskfile tasks |
| Skipping integration tests | Run `task test` before deploy |

## NOTES

- Registry: `oci.seamlezz.com`
- Secrets via OpenBao (Vault fork)
- Proto definitions auto-regenerate via `build.rs`
- NATS subjects defined in `proto/api/`
