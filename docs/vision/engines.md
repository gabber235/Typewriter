# Engines

## What it is

An engine is the thing that actually executes content. It takes published content as configuration and enacts it, using extensions.

### Capabilities

- A capability is a set of behaviour. An engine that implements a capability must implement **all** of it.
- **Only Typewriter core defines capabilities**, because they exist for engines to implement. Extensions build on each other directly instead (see [extensions.md](extensions.md)).
- **Small and composable, plus named bundles:** small capabilities (player, inventory, world, entity, chat, camera, ...) and bundles of them, such as `Minecraft`.
- Extension code can target capabilities, a specific engine, or nothing (common code); see [extensions.md](extensions.md).
- **Optional use:** extension code can use a capability when the engine has it and fall back when it does not. Example: the player entity uses Minecraft's mannequin entity on versions that have it, and the older fake player approach on versions before that.
- **Version dependent features are capabilities, not version numbers.** Core defines a small capability per feature that only some versions have (for example `NativeDialogs`, `Mannequins`). An engine implements the ones its running version supports. The panel catalog for a book shows the entries whose **required** capabilities every engine running that book has; entries that use them **optionally** stay and fall back at runtime. Like feature detection over version sniffing in browsers, this also works for engines without Minecraft versions. Tradeoff: core's list of small capabilities grows over time.

  ```
  Paper 1.21.6:  NativeDialogs, Mannequins
  Paper 1.20.4:  neither
  book on both   -> catalog hides entries that require NativeDialogs
  ```
- **Mixed engines in one realm:** if a Paper and a Fabric engine both support a book, the book runs on both at once, sharing stored data.
- Capabilities can be mixed and matched, so new engines are cheaper to build.

Example: a `Minecraft` capability. The basic extension targets it. If a Fabric engine were ever built and implemented `Minecraft`, everything targeting that capability would work on it automatically.

### Known and possible engines

| Engine | Status | Purpose |
| --- | --- | --- |
| Paper engine | exists | Runs on a Paper server; serves protagonists |
| Panel engine | planned, not started | Runs interactive content inside the panel itself |
| Fabric engine | hypothetical | Not planned; used as the example of why capabilities exist |
| Hytale engine | someday idea | A non Minecraft game; content there has no Minecraft capability |

### Panel engine

Typewriter makes it easy to create quests and teach people about a Minecraft server. The panel engine applies the same concepts to teaching people **Typewriter itself**.

- The user of the panel is the "player" of this engine.
- Custom entries and extensions exist specifically for it.
- It needs a realm, so it always runs embedded next to the realm.
- Content can be installed from elsewhere. Example: a button in the documentation that downloads a tutorial and starts it.
- Tutorials are interactive and quest like: they notice what the user configured ("you configured it this way", "you did this here") and react.

## Who it serves

Extension developers (write once against capabilities), server owners (choose engines), protagonists, and panel users learning Typewriter.

## Why

Capabilities decouple extensions from a specific runtime, so content and extensions keep working when new engines appear.

## Horizon and maturity

| Item | Horizon | Maturity |
| --- | --- | --- |
| Capabilities, complete implementation rule | closed beta | shaped |
| Capabilities defined only by core; small ones plus bundles | closed beta | shaped |
| Optional capability use with fallback | closed beta | shaped |
| Same book on several engine types at once | someday | shaped |
| Version dependent features as capabilities; catalog filtered per book | closed beta | shaped |
| Paper engine | closed beta | shaped |
| Panel engine (not a closed beta priority) | later | sketch |
| Other Minecraft engines (Fabric, Minestom) | someday | wish |
| Hytale engine | someday | wish |

## Open questions

- None yet.
