# Book composition

How books connect: a book that applies only to some protagonists, inlets and outlets that relay links across a book's edge, and a book embedded in another book as an entry. Variables, instances, and copies themselves are in [formula-language.md](formula-language.md#book). Layer 31 rough design, decided 2026-11-06.

Nothing here is built yet. See [Not proven](#not-proven).

## End to end

Scenario: the Village smith asks "Iron or gold?". The answer starts Fetch quest, a book used as a building block, which asks for the item and waits for it. When it completes, the smith thanks the player for the amount handed in. Fetch quest applies only from level 10. Ann is level 12, Bo is level 4.

### 1. The books

```
Book: Fetch quest
  variables:  item: context(chain: Chain) () -> Item     // per run
              amount: Int = 1                           // at publish
  condition:  protagonist.level >= 10
  page:       started (inlet) -> ask_line -> wait_for_item -> completed (outlet)
                                              wait_for_item -> gave_up (outlet)
  definition: delivered: context(chain: Chain) () -> Int = wait_for_item.handed.amount

Book: Village
  page:       smith_question -> fetch_iron.started
              fetch_iron.completed -> reward_line
              fetch_iron.gave_up -> sorry_line
  fetch_iron: EmbedBook of Fetch quest, InstanceChoice.New(item = smith_question.chosen.item, amount = 3)
  reward_line.text = "Thanks for the ${fetch_iron.delivered} iron"
```

`handed` stands for a record `wait_for_item` produces (`produces { field("handed", Handed) }`).

The condition is a book field:

```kotlin
data class Book<V : Record>(
    /* library, title, icon, color, tags, pages, configurations, variables, instances, imports */
    val condition: Var<Boolean, BookContext> = Var.Value(true),
) : Resource, ConfigurationHolder

// formula context of a book condition; book variables arrive through scope like in any entry
interface BookContext { val protagonist: Protagonist; val engine: Engine }
```

### 2. Inlets and outlets

An inlet and an outlet are named relay points on a page. Seen from the book they sit in, a link comes into the book through an inlet and leaves it through an outlet. They are not triggerables and have no handler: they take the shape of what they connect, and publish removes them.

```kotlin
// authored only; publish removes both
data class BookInlet(
    /* page, name, placement */
    val through: Set<Ref<RelayThrough.Inlet, Resource>> = emptySet(),
) : Element

data class BookOutlet(/* page, name, placement */) : Element   // only linked into

@TypewriterRelationFamily(RESOURCE_RELAY_FAMILY_ID)
interface Relaying

const val RESOURCE_RELAY_FAMILY_ID = "resource.relay"

@ReferenceContract(RELAY_THROUGH_RELATION_ID)
interface RelayThroughContract : Relaying {
    interface Inlet : One<BookInlet>
    interface Target : Many<Resource>   // any entry, manifest element, or other resource
}
```

The module declares `@TypewriterTypeImports(Resource::class)`, as the codegen fixture `universal_resource_endpoint.kt` does. A relation in the `resource.relay` family is read through a `relaying` getter next to `ownsResources` and `isAcyclic` (`RelationContract.kt`).

**One validity rule:** a link to or from a relay is valid when every link it becomes after rewiring is valid.

- A link into an inlet fits when it would fit every resource the inlet's `through` targets.
- A link from an outlet fits when every link into the outlet could point there directly.
- The relation of a rewired link comes from the side that is not a relay.
- An endpoint in the `resource.relay` family accepts any resource. `Resource` is not readable as a catalog type (KSP drops it as a parent), so this is the predicate's job, not `isReadableAs`.

The rule is one shared predicate, used wherever a link target is checked today: `ResourceValueMapper.project` (`source_resource_type_mismatch`, `target_resource_type_mismatch`, `binding_target_type_mismatch`), `RelationReads.accepts`, `RealmGraphFacts.linkCapacityOf`, search, and the panel's `linkTargets`. It records reads of the relay's links, so editing an inlet's `through` rechecks every link coming in.

A link from an inlet to an outlet passes straight through, and rewiring repeats. A loop across books is a publish error.

### 3. The embed

An embed places a book inside another book as one entry. Its fields come from the embedded book through `bind`, live while editing, not at publish ([formula-language.md](formula-language.md#bind)).

```kotlin
class EmbedBook<V : Record, I : Record, O : Record>(
    /* page, name, placement */
    val book: Ref<EmbeddedBook.Embed, Book<V>>,
    val instance: InstanceChoice<V>,
    val inlets: I,    // one back link field per inlet of the book: links into the book
    val outlets: O,   // one link field per outlet of the book: links out of the book
) : Entry

sealed interface InstanceChoice<V : Record> {
    data class New<V : Record>(val values: V)                // a new instance; shows every variable
    data class Existing<V : Record>(val keys: Set<String>)   // one or more listed instances
    class All<V : Record> : InstanceChoice<V>                // every listed instance
}
```

- `V` is the embedded book's own variables type: the bind reuses the book's `content(variables)` id, so both share one type.
- `I` and `O` are derived from the book's inlets and outlets.
- An outside link names the inlet through the existing `opposite` path, so both sides are stored, as for any link authored on both sides (`ResourceValueMapper.kt:215-227`):

```kotlin
smith_question.triggers   = [Ref(fetch_iron, opposite = [inlets, started])]
fetch_iron.inlets.started = [Ref(smith_question, opposite = [triggers])]
```

A book's instances are its listed instances plus every `New` embed of it. A book with none of either has exactly one root copy. So a book embedded with `New` never also runs by itself. A `New` embed's path is its name below the embedding copy's path: `["fetch_iron"]`, or `["riverside", "fetch_iron"]` when Village lists `riverside`. A path that two instances share is a publish error.

### 4. Publish

Publish makes the copies ([formula-language.md](formula-language.md#copies-at-publish)) and rewires every link through a relay to the link it stands for. No relay and no embed is compiled.

```
// authored
smith_question.triggers  -> fetch_iron.inlets.started     // in Village
started.through          -> ask_line                      // in Fetch quest
wait_for_item.triggers   -> completed                     // in Fetch quest
fetch_iron.outlets.completed -> reward_line               // in Village

// published, relation = triggers in both
CompiledEdge((smith_question, [])            -> (ask_line,    ["fetch_iron"]))
CompiledEdge((wait_for_item, ["fetch_iron"]) -> (reward_line, []))
```

- A rewired edge keeps the non relay side's location and has `second_location = null`, because a relay holds no opposite field.
- An inlet with two targets turns one authored link into two published links. A `One` field through it is therefore a link error, caught by the validity rule.
- `Existing` and `All` make no copies: their links fan out to the listed instances' copies.
- Hydrated links come from these edges, never from the authored `Ref`, which holds only a `ResourceId` ([formula-language.md](formula-language.md#copies-at-publish)).

### 5. Values in and out

**In:** a variable whose type is a function with `chain` in its context is filled per run. The value is written where the embed sits, so `smith_question.chosen` resolves in Village (the short form `chosen` walks back from the embed). The link from `smith_question` carries the chain into `ask_line@fetch_iron`, so `wait_for_item` still finds `chosen` when it calls `book.item`.

```
// wait_for_item, a MemberContext formula: chain is in its context
held(book.item) >= book.amount
```

A formula without `chain` in its context (a manifest element, the book's `condition`) cannot call `book.item`: a type error while editing. Only `New` embeds can pass per run values; listed instances get theirs from the book's own list.

**Out:** the book decides what leaves it through a `Definition` with a function type, which is exported by default. An embed exposes its copy's exports like an import of one instance: `fetch_iron.delivered`. The link from `completed` carries the chain to `reward_line`, so the chain still holds `wait_for_item`'s record. If `reward_line` can be reached without passing through the book, `fetch_iron.delivered` is nullable, like a chain record not on every path. With `Existing` holding several keys or `All`, the caller picks one like an import: `town_intro.riverside.greeting`.

Nothing outside a book names an entry inside it: renaming `wait_for_item` never breaks Village.

### 6. Conditions

An element applies to a protagonist when every book on its instance path applies: `ask_line@["fetch_iron"]` needs both Village's and Fetch quest's conditions. Each copy knows its books, set at publish.

```kotlin
fun Element.appliesTo(who: Protagonist): Boolean   // every book on the path, BookContext(who, engine)

fun Element.appliesTo(subject: Holder): Boolean = when (subject) {
    is Protagonist -> appliesTo(subject)
    is GroupIdentity -> subject.members().any { appliesTo(it) }   // members from Membership (layer 11)
    else -> true   // Session, Engine: content without a protagonist always runs
}
```

When a book does not apply, its content acts as if it does not exist for that protagonist. Core filters in four places:

| Place | Effect |
| --- | --- |
| `Candidate<E>` | No run for an entry that does not apply to the subject ([events-and-handlers.md](events-and-handlers.md#resolution)) |
| `fire` | A link into an entry that does not apply to the subject is skipped |
| A derive with an entry or `Running` receiver and a `who` parameter | Runs only for members the entry applies to, so their holds and views never appear |
| `Queued.gaveUp` | A queued step whose entry no longer applies leaves the queue ([interactions.md](interactions.md#the-queue)) |

A group is never rewritten. The `who` filter narrows what each member sees and takes; `group` in formulas stays the whole group. Stored data of a book that does not apply is kept, unused.

Demand: every conditional book's condition is watched for every online protagonist from `SessionArrived` ([live-data.md](live-data.md#demand)). A `Var.Value(true)` condition is no formula and costs nothing.

### 7. Stopping

When a condition turns false mid interaction, the part from that book stops at once.

```kotlin
data class BookGone(@Key val step: Step, val whole: Boolean) : Live

@Derive
fun Running<*>.bookGone(start: InteractionStart): BookGone? = when {
    !start.entry.appliesTo(subject) -> BookGone(step, whole = true)
    !entry.appliesTo(subject) -> BookGone(step, whole = false)
    else -> null
}

@Handler
fun Added<BookGone>.stop(row: Running<*>) {
    val _ = StopForBook(row, value.whole).attempt()
}

@Transaction context(tx: Transaction)
fun stopForBook(row: Running<*>, whole: Boolean) {
    if (whole) interactionStart(row.interaction).clear() else running(row.step).clear()
}
```

- `start` is filled from `Running.interaction`, the key of `InteractionStart`.
- `whole`: the book the interaction started in no longer applies, so the whole interaction ends with its identity. Otherwise only the step from the embedded book ends, and its links do not fire.
- For a group subject this happens when the book applies to no member; a member it stops applying to only loses their view through the `who` filter.

### 8. The whole run

1. Ann clicks the smith. `smith_question` runs and produces `chosen = iron`.
2. Its link, published as `smith_question -> ask_line@["fetch_iron"]`, fires. Ann is level 12, so `fire` follows it.
3. `ask_line` asks for 3 iron; `wait_for_item` reads `book.item`, which calls `smith_question.chosen.item` with Ann's chain.
4. Ann hands in 3 iron. `wait_for_item` produces `handed` and its link `-> reward_line@[]` fires.
5. `reward_line` says "Thanks for the 3 iron" through `fetch_iron.delivered`.

Bo clicks the smith: `smith_question` runs, but `fire` skips `ask_line@["fetch_iron"]` for him.

## When things go differently

| Case | What happens |
| --- | --- |
| Ann's level drops to 9 while she waits for the item | `BookGone(whole = false)`: the Fetch quest step ends, no outlet fires |
| Ann gives up in the queue | `gave_up` fires and `sorry_line` runs |
| Town intro lists `riverside` and `hillfort`, condition `protagonist.town == book.town`, embedded with `All` | One link reaches both copies; `fire` follows only Ann's town |
| Fetch quest gets a listed instance too | Listed instances and `New` embeds coexist; the listed one runs by itself |
| An inlet links to a trigger and to an audience | Outside trigger links fail the rule (they do not fit the audience); use two inlets |
| A book embeds itself, directly or through another book | Publish error |
| A world trigger inside Fetch quest ("every day at 18:00") | Runs in every copy; conditions do not apply to it |

## What this adds and removes

| Adds | Removes |
| --- | --- |
| `condition`, `BookContext`, `appliesTo`, `BookGone` | Legacy criteria on books |
| `BookInlet`, `BookOutlet`, the `resource.relay` family, one validity predicate | A handler and an extra event hop per book crossing |
| `EmbedBook<V, I, O>`, `InstanceChoice` | A separate catalog type per book, and the catalog invalidation every book edit would cause |
| Per run variables and exported definitions across embeds | A second way to pass values (inputs on inlets, values on links) |

## Not proven

Nothing compiled or ran. Checked against code: KSP accepts a universal endpoint (`universal_resource_endpoint.kt:19`, compile only); the hard link checks run before `accepts` (`ResourceValueMapper.kt:191-213`); `isReadableAs(_, Resource)` is false (`KspTypeGraphConverter.kt:281`); the engine keys by the full `CompiledResourceKey`, so copies never collide (`CompiledResourceGraph.kt:25-39`).

- **`bind`, `dynamic()`, and `Book<V>` are not built** (`LibraryModel.kt:79-86` has no variables). Layer 31 waits on layers 11 and 13.
- **The id of `I` and `O`.** A derived type's id is the location of the field the bind reads; `I` and `O` come from many relay resources, so the rule needs to name the field the bind is declared on.
- **`book.contents<BookOutlet>()` inside `dynamic()`.** Only `ref.resolve()` and field reads are designed as tracked reads; this is a chain of field reads over pages.
- **`Book<V>` as a reference target** in `Ref<EmbeddedBook.Embed, Book<V>>`.
- **The back link fields on the embed** belong to whichever relation the outside link uses, so the relay family rule must also cover the embed's `inlets` fields. Whether the panel's link drag writes both sides for a relation it learns from a bind.
- **A universal endpoint in a realm test.** Only the KSP fixture exists.
- **Chain through a rewired edge.** Assumed to carry the context like any link.
- **A `Definition` body with `chain`.** `DefinitionScope` is the definition's surroundings and a function's own context parameters are in scope, but no example uses `chain`.
- **`members()` on a group identity** is assumed from `Membership`.
- **Cost of conditions.** Conditions times online protagonists.

## Open

- A formula field for `Existing.keys`, so "every town that has a market" follows the list.
- The panel's embed node with inlet and outlet slots.
- Repair when an inlet or outlet is renamed or removed while embeds link to it.
- Link context type checks and conversions from the vision (`content-model.md`) have no layer yet.
