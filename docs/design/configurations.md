# Configurations

Configurations replace the legacy snippets. An extension writes a plain typed record. Creators make named versions of it, select one on the realm, a book, a page, or an entry, and change single values on an entry. Publishing works out the final values, so handlers read plain typed fields. Decided 2026-11-05 in the layer 12 rough design.

Nothing here is built yet. See [Not proven](#not-proven).

The panel and core never mention configurations. Each need is met by a general part, listed under [General parts](#general-parts); only `Configuration` and `Configured` know about them.

## End to end

Legacy spoken dialogue has five loose values (`SpokenDialogueCinematicEntry.kt` on `develop`), such as:

```kotlin
val spokenMinLines: Int by snippet("cinematic.dialogue.spoken.minLines", 4)
```

### 1. The extension writes a record

The record knows nothing about layers. Its defaults are the last layer, so a new server works with no setup.

```kotlin
@TypewriterType(id = "...")
data class SpokenDialogueConfiguration(
    // A function, so speaker and message are checked names, not "<speaker>" text.
    val format: Var<(speaker: RichText, message: RichText) -> RichText, MemberContext> = ...,
    val minLines: Var<Int, MemberContext> = ConstVar(4),
    val maxLineLength: Var<Int, MemberContext> = ConstVar(40),
    val percentage: Var<Double, MemberContext> = ConstVar(0.5),
)
```

### 2. The entry uses it, with composition

```kotlin
class SpokenDialogueEntry(
    /* page, name, placement, triggers */
    val text: Var<RichText, MemberContext>,
    val dialogue: Configured<DialogueConfiguration> = Configured(),
    val spoken: Configured<SpokenDialogueConfiguration> = Configured(),
) : DialogueEntry
```

### 3. Core holds the layers

`Configuration` is one root resource type, like `Tag` or `Book`. Its `C` is the picked type argument, as on `Definition<T>`. Every layer is the same `Partial<C>`: `C`'s fields, each nullable.

```kotlin
data class Configuration<C>(val values: Partial<C>) : Resource

data class Configured<C>(
    val selected: Ref<Configuration<C>>? = null,
    val overrides: Partial<C> = Partial.empty,
) {
    val value: C   // filled at publish
}

// Book, Page, and RealmRoot.
interface ConfigurationHolder {
    val configurations: List<Ref<Configuration<*>>>   // at most one per C
}
```

### 4. Creators set values

```
Root            configurations = ["House style"]       shown as the Default
"House style"   SpokenDialogueConfiguration { percentage = 0.3 }

Book "Dragon"   configurations = ["Boss speech"]
"Boss speech"   SpokenDialogueConfiguration { maxLineLength = 60 }

Entry dragon_line   spoken = Configured(overrides = {
                        minLines = if (protagonist.vip) 8 else 6
                    })
```

### 5. Publishing works out each field

Every level adds up, and the first value per field wins (decided 2026-11-05). The order walks the owner chain, so a new level between page and book needs no code.

```
entry overrides > entry selected > each owner, nearest first > Kotlin default
```

| Field of `dragon_line` | Value | Comes from |
| --- | --- | --- |
| `minLines` | The VIP formula | Entry override |
| `maxLineLength` | 60 | "Boss speech", from the book |
| `percentage` | 0.3 | "House style", from the root |
| `format` | The code's default | Kotlin default |

```kotlin
// On portable records, for any type. First non null per field.
fun merge(layers: List<RecordPayload>): RecordPayload

fun holders(resource: ResourceId) =
    generateSequence(resource, graph::ownerOf).filter { it.isA<ConfigurationHolder>() }
```

### 6. The handler reads plain fields

Handlers never see `Partial`.

```kotlin
@Derive
fun Speaking.show(context: MemberContext): DialogueHold {
    val spoken = entry.spoken.value
    val lines = text.wrap(spoken.maxLineLength(context), spoken.minLines(context))
    return DialogueHold(spoken.format(context)(speaker, lines))
}
```

## In the panel

Most of the time a creator does not care about configurations, so the entry editor has three levels (decided 2026-11-05, as a section at the bottom):

| Level | What shows |
| --- | --- |
| Just writing | One collapsed `Configuration` row with the selected names. A chip shows when values changed |
| Pick another | One picker per type. "Inherit" names what would apply and from where |
| Change one value | Each value, muted, with its source. Clicking it starts an override, and reset removes it |

The realm sidebar gets a `Configurations` section, like `Tags`, with cards grouped by type. The one selected on the root shows as `Default`, and "Edit defaults" creates one when none exists. A record's own presentation decides how its inspector looks, so an extension can add a live preview of its format.

```kotlin
data class Configurations(val items: List<Ref<...>> = emptyList()) : RealmSection

object ConfigurationsWorkspace : ConfigurationsPresentation {
    override val roles = setOf(PresentationRole.WORKSPACE)
    override fun ConfigurationsPresentationScope.present() { items { grid() } }
}
```

## General parts

| Need | General form | Also serves |
| --- | --- | --- |
| A field says where it belongs | `group` on a presentation | Rare extension fields, generated item fields, placement sections |
| Null means something else applies | `NullableControl`, extended | Game defaults as [hints](generated-types.md#automatic-corrections) |
| A record whose fields can all be absent | `Partial<T>` | Named configurations and overrides |
| A top to the tree | Walking the owner chain | [Inherited priority](events-and-handlers.md) |
| The panel needs a computed value | Existing computations (`RealmCapabilityInvocationSource`) | Any computed panel value |
| A value shown small | Existing `item` role | Collection rows |

### A field says which group it belongs in

Today an inspector decides placement, so every inspector would have to know every type. A filter by type would be a patch. `remainingFields()` in `ElementSdkProvider.kt` stays as it is.

```kotlin
object ConfiguredInspector : ConfiguredPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)
    override val group = FieldGroup("configuration", "Configuration", collapsed = true)
}
```

```dart
// delegation.dart, the remaining fields loop
for (final field in checked.fields(selection)) {
  if (excluded.contains(field.template.key)) continue;
  final group = checked.fieldGroup(selection, field, role); // null: stays inline
  (group == null ? children : groups[group]!).add(...);
}
// Each group renders as the existing collapsible section.
```

### Null can mean "something else applies"

`NullableControl` already has `empty_text` as an expression. It gains one field, and a clearer look than today's switch: the hint is muted, clicking fills it, and `clear_label` is the reset.

```
struct NullableControl {
  control: BoundControl = 0;
  value_presentation: PresentationNode? = 1;
  empty_text: ExpressionNode? = 2;     // "60, from Boss speech"
  clear_label: ExpressionNode? = 3;    // "Reset"
  initial_value: ExpressionNode? = 4;  // filling it starts from this
}
```

## When things go differently

| Case | What happens |
| --- | --- |
| Nothing set anywhere | Kotlin defaults |
| Selected configuration deleted | The reference relation clears or reports it, as any `Ref` does |
| An extension adds a field | Nothing stored changes, and the Kotlin default applies |
| An extension removes a field | The [developer migrator](migrations.md#developer-migrator), as for any type revision |
| A formula in a configuration | Sees `protagonist`, not a book's names, because a configuration is shared across books |
| Two of one type on a holder | A realm check error |
| Code with no entry | 5 legacy files, such as `ChatHistoryHandler`. A handler parameter gives the root's value: `fun Tick<EverySecond>.x(config: ChatConfiguration)` |
| Hot publish | Final values change with the content switch, so running dialogues update |

## What it removes

- All 129 `snippet()` values, and the loose text format with `<speaker>` tags.
- Legacy `config()` is a different thing: `typingDurationType` moves to `DialogueConfiguration`, and panel and websocket settings are gone.

## Not proven

- **Nothing ran.** All Kotlin here is a sketch.
- **`Partial<T>`.** `CheckedCatalog` has no type computed from another type today. The fallback is KSP writing one per type, about 240 lines plus 82 per field.
- **`Configured.value`.** A field filled at publish and never stored has no precedent in the entry classes.
- **Function field with a default.** Function fields are designed ([formula-language.md](formula-language.md#type-checking)), but not with a default in Kotlin.
- **Computations.** They exist, but no one confirmed that a presentation can read one's result.
- **`item` role.** It is documented for resources, so using it for a value needs checking.
- **A record's own look.** A presentation written for `C` must also work over `Partial<C>`.
- **`group`.** `PresentationDescriptor` has no such field yet, and the renderer must resolve each field's presentation first.
- **Cards grouped by type.** Not checked against the grid layout.
- **Name clash.** "Configuration" already means something in code (`AuthoringRecord.configuration`, `ConfigurationProvider`) and in `Tick<C>`. One of them needs renaming in the plan.
