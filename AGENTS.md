# PROJECT KNOWLEDGE BASE

**Generated:** 2025-12-30
**Branch:** features/v1

## OVERVIEW

TypeWriter: Minecraft Paper plugin for interactive quests, NPC dialogues, and cinematics. Polyglot monorepo: Kotlin engine + extensions, Flutter panel, Rust/wasmCloud backend, shared Protobuf contracts.

## STRUCTURE

```
typewriter/
├── engine/           # Kotlin - Paper plugin core (loader, API)
├── extensions/       # Kotlin - Modular feature JARs (Basic, Entity, Quest...)
├── module-plugin/    # Kotlin - Gradle plugin + KSP for extension building
├── panel/            # Dart/Flutter - Web/desktop configuration UI
├── app/              # Dart/Flutter - Legacy/shared components
├── backend/          # Rust/wasmCloud - Identity, auth, org management
├── services/         # Kotlin - Microservices (realm) via NATS
├── proto/            # Protobuf - Shared contracts (Panel <-> Backend <-> Engine)
├── documentation/    # TypeScript - Docusaurus site
├── marketplace/      # TypeScript - SvelteKit extension marketplace
├── discord_bot/      # Rust - Discord integration
└── code_generator/   # Rust - Entity/material code generation
```

## ARCHITECTURE

```
┌─────────────────┐     NATS/Protobuf     ┌──────────────────┐
│   Panel (Web)   │◄────────────────────►│  Backend (Rust)  │
│   Flutter/Dart  │                       │    wasmCloud     │
└────────┬────────┘                       └────────┬─────────┘
         │ NATS/Protobuf                           │ SurrealDB
         ▼                                         ▼
┌─────────────────┐                       ┌──────────────────┐
│  Engine (Paper) │◄── JAR Loading ──────│   Extensions     │
│     Kotlin      │                       │     Kotlin       │
└─────────────────┘                       └──────────────────┘
         ▲
         │ Depends on
┌─────────────────┐
│  module-plugin  │ ── KSP generates blueprints for Panel
│  Gradle Plugin  │
└─────────────────┘
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add new entry type | `extensions/BasicExtension/` | Use `@Entry` annotation |
| Add entity support | `extensions/EntityExtension/` | Minecraft entity logic |
| Modify panel UI | `panel/lib/widgets/` | Flutter components |
| Add API endpoint | `backend/` + `proto/api/` | Define proto first |
| Update shared models | `proto/models/` | Regenerate in panel + backend |
| Add documentation | `documentation/docs/` | MDX, code in `_DocsExtension` |
| Create new extension | `extensions/` | Copy existing, use `typewriter` Gradle plugin |

## COMMANDS

### Engine & Extensions (Kotlin)
```bash
cd engine && ./gradlew build          # Build engine
cd extensions && ./gradlew build      # Build all extensions
./gradlew buildRelease                # Production JARs
./gradlew test                        # Run tests
```

### Panel (Flutter)
```bash
cd panel
task proto                            # Generate Dart from proto
task generate                         # Run build_runner (freezed, riverpod)
task panel:run:web:local              # Dev server
flutter test                          # Run tests
```

### Backend (Rust/wasmCloud)
```bash
cd backend
task build                            # Build all services (wash build)
task push                             # Push to OCI registry
task deploy                           # Terraform deploy
```

### Documentation
```bash
cd documentation
npm ci && npm run build               # Build site
npm run test                          # Validate build
```

### Local Development
```bash
docker compose up                     # SurrealDB + WasmCloud + Marketplace
```

## CONVENTIONS

### Kotlin (engine, extensions, module-plugin, services)
- 4 spaces, 120 char lines
- Guard clauses over nested conditionals
- Composition over inheritance
- KDoc: explain **when** to use, not what it does
- **No inline comments** - refactor unclear code instead

### Dart/Flutter (panel, app)
- **Double quotes** required (`"string"` not `'string'`)
- **Trailing commas** on multiline args
- **Package imports only** - no relative imports
- Files under 300 lines
- Riverpod for state management

### Protobuf
- `snake_case` fields, `PascalCase` messages
- Enums: prefix with type name, `_UNSPECIFIED = 0` first
- Packages: `typewriter.models.v1`, `typewriter.api.v1`

### Documentation
- **Never edit `docs/adapters/`** - auto-generated
- Code snippets in `extensions/_DocsExtension` only
- Use `<CodeSnippet tag="..." />` component
- Never manually edit `snippets.json`

## ANTI-PATTERNS

| Pattern | Why Bad | Alternative |
|---------|---------|-------------|
| Inline comments | Code should be self-explanatory | Refactor for clarity |
| Relative imports (Dart) | Breaks tooling | Use package imports |
| Single quotes (Dart) | Project convention | Use double quotes |
| Code in docs directly | Breaks snippet system | Put in `_DocsExtension` |
| Manual `snippets.json` | Auto-generated | Use code-block tags in Kotlin |
| Editing `docs/adapters/` | Auto-generated | Source lives elsewhere |

## MODULE-SPECIFIC INSTRUCTIONS

Each major directory has its own `AGENTS.md` with detailed instructions:
- `engine/AGENTS.md` - Engine build, submodules, testing
- `extensions/AGENTS.md` - Creating/modifying extensions
- `module-plugin/AGENTS.md` - Gradle plugin development
- `panel/AGENTS.md` - Panel UI, state, NATS communication
- `app/AGENTS.md` - Legacy Flutter app
- `documentation/AGENTS.md` - Docs, snippets, components
- `backend/AGENTS.md` - wasmCloud services
- `services/AGENTS.md` - Kotlin microservices
- `proto/AGENTS.md` - Protobuf conventions

## NOTES

- **Blueprints**: Extensions define entries via annotations. `module-plugin` KSP generates JSON blueprints that Panel uses to render dynamic forms - no Minecraft logic in Panel.
- **NATS**: Central message bus. Panel gets JWT from Backend (Sentinel auth) to connect.
- **Proto regeneration**: After changing `.proto` files, run `task proto` in panel. Backend regenerates automatically via `build.rs`.
- **Version compatibility**: Extensions declare compatible engine versions. Loader validates at runtime.
