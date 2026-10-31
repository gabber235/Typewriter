# Migrations

How data outside the content follows when content or a type changes. One mechanism covers both cases:

| Trigger | Who writes the step | `old` is | Runs |
| --- | --- | --- | --- |
| A creator changes content (a variable's type, a removed quest stage) | The content type's generated `XMigrations` hook, with creator inputs | The last published view | At publication |
| A developer ships a new revision of a Typewriter type | The developer of that type | The previous revision's view | At publication of the content that uses the new revision |
| A host still holds legacy 0.9 data | The importer (a separate one time tool) | Not applicable | Once per host |

These are content and data migrations. They are unrelated to the realm's database schema patches (`MigrationResources` in `services/runtime/realm`).

## When a migration is needed

A migration is needed when content changes and something outside the content must follow: stored data or running interactions.

| Change | What the migration does |
| --- | --- |
| A variable's type or keys change | Converts every stored value with a conversion formula; the default clears the values |
| An instance key is renamed | Moves the instance's stored data to the new key (through the book's migration) |
| A quest stage is removed | Moves protagonists off the removed stage |
| A running step is removed | Moves or ends the interactions running it |
| A group entry changes | Moves the stored data that depends on it, such as `Membership` |

No migration is needed when:

- A variable is renamed. Storage is keyed by entry id, so the data stays.
- Every stored value still passes `ValueAdmission` for the new shape. Widening `Int` to `Int?` is an example.

Stored values, variables, and `Membership` are explained in [stored-data.md](stored-data.md) and [interactions.md](interactions.md).

## The `XMigrations` hook

KSP generates one hook per content type, `XMigrations`, with the function `fun XMigrationScope.migrate()`. The hook is live on the realm: it reruns while the creator edits.

- `old` is the last published view of the content.
- `new` is the draft.
- `input(name, type, default)` asks the creator for a value the migration cannot decide alone.
- The result is decided `Changes`, the same storage operations an `apply()` commits (see [stored-data.md](stored-data.md)).

For the `Variable` static entry the hook compares type and keys and asks for a conversion formula:

```kotlin
// Generated hook for Variable<K, T>. Sketch of the body; see Open.
fun VariableMigrationScope.migrate() {
    // old = last published Variable, new = the draft
    if (old.type == new.type && old.keys == new.keys) return
    // Ask the creator how an old value becomes a new one.
    // The default clears the stored values.
    val convert = input("convert", type = new.type, default = clear)
    // Produce Changes that rewrite every stored value of this variable with convert.
}
```

Reading `old` needs two realm capabilities: a read of the last published view, and read only access to stored data while editing (for dry runs).

## `PendingMigration`

Creator inputs are stored as ordinary content in a core resource:

```kotlin
PendingMigration(owner, inputs: Map<String, Var<*, MigrationScope>>)
```

- `owner` is the content whose change needs the migration.
- Each input is a `Var`, so it is a value or a formula with the ordinary editor, presentation, and Apply flow (see [formula-language.md](formula-language.md)).
- `MigrationScope` is the scope those formulas see; it contains `old`.
- Unfinished inputs block publication.

## The conversion formula

Changing the type of a variable that already has values shows a conversion formula from the old shape to the new one, as an ordinary field.

Example: the `coins` variable changes from `Int` to `String`.

```
"${old} coins"
```

- The default clears the values. The creator replaces it with a formula when the data must survive.
- The formula is a creator formula, not a v1 portable expression.
- The same applies to a key change: the formula maps each old value to its new form, and the key record follows the new keys.

## Checks while editing

The realm checks migrations through the existing `RealmCheckProvider`, computed through the query graph:

| Finding | Level | Effect |
| --- | --- | --- |
| Unfinished migration inputs | Error | Blocks publication |
| A migration dry run fails (for example the conversion formula fails on a stored value) | Error | Blocks publication |

A dry run evaluates the migration against the real stored values, read only, on every edit. The finding shows on the causing field with a quick fix where possible.

## The publication transaction

All pending migrations run in the publication transaction, together with switching the content.

1. The draft's checks pass.
2. Every `PendingMigration` produces its `Changes`.
3. The content switches to the draft.
4. Both commit as one transaction.

- Any failure changes nothing: no data is converted and the old content stays live. The publication shows the error.
- Change operations are applied by the realm's storage, which needs no engine running, so offline protagonists are migrated too.
- After the commit, `Changed<X>` handlers run as for any other `apply()`.
- Running interactions see the new content through hot publish (see [interactions.md](interactions.md)).

Rolling a production realm back to an earlier revision is a realm mode feature, not part of a migration: see [../vision/realm-modes.md](../vision/realm-modes.md).

## Developer migrator

Developer defined stored types are Typewriter types, because they are persisted. They carry an id and a revision, like entry and configuration data:

```kotlin
@TypewriterType(id = "...", revision = 2)
data class Friendship(@Key val pair: Set<Protagonist>, val level: Int) : Stored
```

When a type's revision changes, the migrator is the same step as a content migration:

- `old` is the previous revision's view, `new` is the current one.
- It produces `Changes` that run in the publication transaction.
- It uses the same checks, dry runs, and all or nothing rule.

Types without a revision never migrate this way:

- Derived types (a book's `V`, id is resource id plus parameter name) are rebuilt by `dynamic()`; `ValueAdmission` flags instances that no longer fit.
- Formula types described with `TypeDefinition` have no id or revision.

## Importer for 0.9

The importer moves legacy 0.9 content and data into the new model once per host, then never runs again. It is a separate tool, not a migration step. See [../vision/importer-and-migrator.md](../vision/importer-and-migrator.md).

## Open

- The exact body API of `migrate()`: how it returns `Changes`, and how `input` names a type and a clearing default.
- How a developer writes the step between two type revisions (the shape of the revision hook for Kotlin types).
- How the importer detects legacy 0.9 data on a host and asks to import it.
