# Formula language

How formulas work: the field kind that holds them, how content tells the type system what it means, which names a formula can see, how formulas are checked while a creator types, and how and where they run.

Formulas are their own language with their own interpreter in the shared `formula` module. They are not the v1 portable expressions. Portable expressions encode operations the panel must perform; they have no roots, no members on types, and no per field context. Formulas never reuse the expression AST (`ExpressionNode`) or `PortableExpressionChecker`.

The product intent and full syntax tour live in [../vision/formulas.md](../vision/formulas.md). The primitives this builds on are in [overview.md](overview.md).

## Three ideas

A formula is built from three ideas:

- **Types**: every value has a catalog type.
- **Functions**: members and operators are plain functions. Context parameters are filled from scope by type (the same rule as handler parameters) or explicitly; normal parameters are always passed.
- **Scope**: typed named values. Lambdas and blocks stack more levels on top.

Sugar keeps formulas short: nothing in scope needs a prefix, and a call needs no parentheses when nothing is left to pass.

```
quest.coins >= 100 && protagonist.island.island_bank > 0
```

Formulas are side effect free. Conditions, text, verdicts and derives are pure. Update fields describe changes as values and the entry applies them (see [Changes fields](#changes-fields)).

## The Formula primitive in Kotlin

Kotlin formulas are provider functions ([Standard library](#standard-library)); there is no separate derived value concept. A handler or derive reads a `Var` field of its receiver as a plain parameter with the field's name and value type: it receives the field's current value, with the formula context filled from the handler's subject and parameters, and reruns when its `Watched<T>` mirror changes. KSP rejects such a parameter when no receiver field matches its name and type, so a rename is a build error.

```kotlin
@Derive
fun AudienceEntry.inside(
    protagonist: Protagonist,
    @From(Parent::class) inParents: List<InAudience>,
    criterion: Boolean,
): InAudience? = ...
```

Formulas stop propagating when their value is unchanged, and derives run only after all formulas have settled. Derives and their result kinds are in [stored-data.md](stored-data.md), [live-data.md](live-data.md) and [interactions.md](interactions.md).

## Var<T, C>: the one field kind

Every formula field on an entry or resource is `Var<T, C>`. `T` is the value type; `C` is the formula context (what the field's formulas can see). The field text is only the expression, never `amount = ...`.

```kotlin
@TypewriterType(...)
data class GiveCoinsActionEntry(
    val amount: Var<Int, MemberContext>,
    val message: Var<RichText, MemberContext>,
    override val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>,
    override val changes: Var<Changes, InteractionContext>,
) : ActionEntry, Triggerable
```

What `T` is decides what the text may be:

| `T` | The text is | Example text |
| --- | --- | --- |
| A plain type (`Int`, `RichText`, a record) | An expression of that type | `quest.reward * 2` |
| A function type | The function body; the parameters are in scope. A constant ignores them | `protagonist.level * 10` or `12` |
| `Changes` | Change lines | `quest.coins += 50` |
| `Type` | A type expression | `Map<Ref<Npc>, Mood>?` |

Each field has a plain mode (the normal editor for `T`) and a formula mode (text). The panel toggles between them.

### Stored form

A formula is a function value: a formula for `Var<Int, MemberContext>` has type `context(chain: Chain, engine: Engine, protagonist: Protagonist) () -> Int`. A formula context `C` is the context parameters of that function type. `Var`, `Formula` and `FormulaReference` are ordinary declared types in `typewriter-contracts`, next to `Icon` and `Color`:

```kotlin
@TypewriterType(id = FORMULA_TYPE_ID)
data class Formula(
    val source: String,
    val references: List<FormulaReference>,
)

@TypewriterType(id = FORMULA_REFERENCE_TYPE_ID)
data class FormulaReference(
    val at: TextRange,
    val target: Ref<FormulaReferences.Source, Resource>,
)

@TypewriterType(id = VAR_TYPE_ID)
sealed interface Var<T, F> {
    data class Value<T, F>(val value: T) : Var<T, F>
    data class Computed<T, F>(val formula: F) : Var<T, F>
}
```

- Every function type is stored as a `Formula` record: the checked catalog resolves `TypeUse.function` to `Formula`'s schema, while the function type stays the type used for checking. Names in `source` resolve against where the value sits, so no captured values are stored.
- `Var<T, F>` is an existing union (abstract record plus `parents`), so the plain and formula toggle is picking a concrete form (`concreteForms`), the stored form is `NamedValue.actual_type`, and Kotlin decodes it like any sealed type. A plain value nests one level: `Var.Value { value: 50 }`.
- KSP lowers the Kotlin context slot: `Var<Int, MemberContext>` becomes `Var<Int, context(chain: Chain, engine: Engine, protagonist: Protagonist) () -> Int>`, and `Var<Int>` becomes `Var<Int, () -> Int>`. This is one converter rule, next to the one for `Ref`.
- Pure only contexts (`PublishScope`, `TypeScope`) provide no context parameters and lower to `() -> T`. Only context parameters reach stored or live data, so a function type without context is pure by construction (see [Where formulas run](#where-formulas-run)).
- A function typed `T` needs no special case in storage: `Var.Value.value` is already a `Formula`, so its editor is the body editor with no formula switch.

The editor follows from `T`:

| `T` | Editor | Stored as |
| --- | --- | --- |
| A plain type (`Int`, `Boolean`, a record) | Plain input with a switch to formula mode | `Value(50)` or `Computed("base_reward * 2")` |
| A type with a `template` provider (`String`) | Template editor with a switch to formula mode | Without holes `Value("Hello")`; with holes `Computed` whose `source` is the string template expression it means (`"Total: ${total}"`) |
| A function type | Body editor under the read only signature, no switch | `Value(Formula("level * 2"))` |

The template editor ([Text templates](#text-templates)) shows the body without quotes. The body is the inside of the string literal except that `"` is typed freely and saved as `\"`; `${...}` is a hole, `\$` a literal `$`, `\\` a backslash, and string literals accept real line breaks. One panel function, covered by unit tests, maps positions: source position = body position + 1 + the number of `"` before it.

```
body:    She said "hi" to ${npc}
source:  "She said \"hi\" to ${npc}"
```

The panel selects these editors through presentations, with no special case in editor selection:

- `Var` has a default presentation declared next to it in the contracts, built from existing elements: a header toggle (`HeaderBooleanToggleItem`) that switches the concrete form, and a `polymorphic_match` that shows `default_presentation` of `T` for `Value` and `formula_input` for `Computed`. Plain mode is therefore `T`'s own editor.
- `formula_input` is the one new presentation element: a code editor bound to a `Formula` with the modes expression, template and body. It opens the `WatchFormula` subscription and renders the display text, diagnostics, completions, hover and value.
- `formula_input` is built on Flutter's own text field, with no editor package: a `TextEditingController` whose `buildTextSpan` colors references and underlines `TextSpan` details from the snapshot, and a completion popup anchored at the caret with keyboard handling through `Shortcuts` and `Actions`. Typing, mobile keyboards, IME, selection and accessibility come from the platform text field; formulas need no line numbers or folding. Packages checked 2026-11-02: `re_editor` leaves completion UI to the caller, `flutter_code_editor` has no web support, `code_forge` needs a separate web package.
- The panel knows the mode before contacting the realm: function types are visible as `TypeUse.function`, and KSP marks types that have a `template` provider in the editor catalog.

A formula stores no editor mode: on load the template editor opens for a `Value` and for a `Computed` whose `source` is exactly one string template literal; any other formula opens in formula mode.

### Function typed fields

Function types are a structural catalog type with no id:

```
struct FunctionParameterTemplate { name: string = 0; type: TypeTemplate = 1; }
struct FunctionTypeTemplate {
  context: [FunctionParameterTemplate|name] = 0;
  parameters: [FunctionParameterTemplate|name] = 1;
  result: TypeTemplate = 2;
}
// TypeTemplate.function = 5; TypeUse.function = 4 holds the same shape over TypeUse
```

- **Context** parameters fill from scope by type, innermost scope level first; two candidates on one level is an error. They can also be passed by name. A dot call fills the first one: `player.health` is `health(player)`.
- **Normal** parameters are passed explicitly, by position or name, so `bonus` with `level: Int` never picks up an unrelated `Int` from scope.
- Both are in scope in the body by name. A body has no member scope: it writes `protagonist.quests_done`, not `quests_done`.
- Function types carry no default arguments; defaults stay on declared functions.
- Written as `context(protagonist: Protagonist) (level: Int) -> Int`; without context it is `(level: Int) -> Int`.

Kotlin maps onto this: an extension receiver is the first context parameter (KSP names it from its type, like `@Key` fields), `context(...)` parameters follow, and normal parameters stay normal. Generated Kotlin goes the other way: the first context parameter becomes the receiver. Handler parameters and stored reader keys are context parameters.

A book variable of function type lets each instance supply a constant or a formula:

```
reward: context(protagonist: Protagonist) () -> Int
// instance A: 12
// instance B: protagonist.level * 10
```

The book then reads `book.reward`. Dot calls fill the first context parameter: `energy.current` is `current(energy)`.

### Type fields

A field holding a type is `Var<Type, TypeScope>`. Plain mode is a type picker: scalars, generics with argument slots, nullable, function types with named parameter rows and a result, and inline records with named field rows. The same picker chooses a resource's type argument (a `Definition`'s `T`). It is the existing panel type picker (`authored_type_picker.dart`) extended, not a second one: its search list holds code types from the local editor catalog plus creator types in scope from the realm (type position completions of the `WatchFormula` subscription, the existing `scopeAt`); structured builders add function types (context rows, parameter rows, result) and inline records and unions; and an "as text" input is `formula_input` in a fourth mode, `type`. Rows and text both store the same `Type` value. Text mode writes the type as text, parsed by the formula parser's type grammar and checked live:

```
(protagonist: Protagonist, town: Town) -> Int
Map<Ref<Npc>, Mood>?
```

A `Type` value is an ordinary declared union in `typewriter-contracts`, so it is authored content with value paths:

```kotlin
@TypewriterType(id = TYPE_TYPE_ID)
sealed interface Type {
    data class Named(val name: TypeName, val arguments: List<Type> = emptyList()) : Type
    data class Nullable(val value: Type) : Type
    data class Scalar(val kind: ScalarType) : Type          // mirrors ScalarKind
    data class Function(val context: List<Parameter>, val parameters: List<Parameter>, val result: Type) : Type
    sealed interface Declaration : Type
    data class Record(val fields: List<Field>) : Declaration
    data class Union(val fields: List<Field> = emptyList(), val cases: List<Case>) : Declaration
    data class Reference(val target: Named) : Declaration
}
data class Parameter(val name: String, val type: Type)
data class Field(val name: String, val type: Type)
data class Case(val name: String, val declaration: Type.Declaration)

@TypewriterType(id = TYPE_NAME_TYPE_ID)
sealed interface TypeName {
    data class Catalog(val id: CatalogTypeId) : TypeName    // a TypeId, no revision
    data class Content(val at: BoundPath<Type>) : TypeName
}
```

- References carry no revision: content always means the current revision of a catalog type.
- Every `Declaration` is a content type with id `content(at)`, where `at` is its own location: the stored path in plain mode, or the path inside the computed `Type` value in formula mode. Each `Case` is its own content type whose parent is the union; `Union.fields` are inherited by every case, like properties on a Kotlin sealed interface.
- A case is always a new declaration (a record, possibly empty, or a nested union). An enum is a union whose cases are all empty records, `union { Open, Closed }`; the panel shows it as a dropdown, never a reference: parents are declared on the subtype and `Scalar` or `Function` values carry no `actual_type`.
- A creator type whose value is `Named(...)` is an alias.
- A `Reference` (written `Ref<Npc>` in type text) declares its own relation contract at its location, as KSP does for a Kotlin `@ReferenceContract`: the first endpoint is the content holding the reference (`many` inside a list, set or map, `one` otherwise), the second is the target type and is never authored on the target (`LinkTarget.opposite` stays absent), and deleting the target clears the link, so the field becomes `unfilled` and the completeness check blocks publish until it is fixed. `RelationId` gets a `content(at: ValueLocation)` variant next to its declared string, mirroring `TypeId`. Kotlin keeps the two argument form `Ref<Contract.Side, T>`.
- `dynamic()` lowers a `Type` value to the checker's `TypeUse` in the query graph: `Named(Catalog(id))` to `named(TypeDefinitionId(id, current revision))`, `Named(Content(at))` to `named(content(at))`, a `Declaration` at L to `named(content(L))` plus its registered `TypeDefinition`, and `Function`, `Nullable`, `Scalar` to their `TypeUse` shapes.
- The type picker is a custom editor for `Type` through the existing presentation mechanism.

### Changes fields

An update field is `Var<Changes, C>`. It holds several change lines that run in order; later reads see earlier pending changes. The formula only carries the changes; it writes nothing.

```
quest.coins += 50
quest.stage = forge_sword
if (quest.coins > 100) quest.rank = gold
group.members.forEach { it.reputation += 5 }
```

`Settable` members come from `stored()` declarations and their keys fill from scope. Change operators are plain stdlib provider functions; the operations they produce are in [stored-data.md](stored-data.md#change-operations).

Assigning inside a verdict or another pure field is a type error. Update fields may set and update stored values only, never world actions such as giving items; those stay explicit entries. The change operations, transactions and the `Triggerable` trait are in [stored-data.md](stored-data.md).

## Formula contexts

A context is a plain Kotlin interface whose properties are the scope values a field gets. KSP turns `C` into the field's `scope` call. The code that evaluates the field (the entry's handler) passes an instance, with core helpers for core contexts:

```kotlin
interface InteractionContext { val chain: Chain } // `protagonist` or the widened `group` comes from `produces`
interface MemberContext : InteractionContext { val protagonist: Protagonist }

interface ShopItemContext : MemberContext { val item: ShopItem }

val text = entry.text(memberContext(member))
```

Inheritance lets a formula written for a wider context fit a narrower one. `Var<T>` without a context gets only the surrounding scope.

Core defines every context. Capability modules define none: engine values are generated readers of mirrors, and names such as `minecraft` are top level providers. So contexts stay engine neutral. Extensions extend a core context.

| Context | Used by | Provides |
| --- | --- | --- |
| `InteractionContext` | Fields evaluated once per interaction | `chain`, `engine`, plus the chain's subject: `protagonist`, or `group` after widening |
| `MemberContext` | Fields evaluated per member | `InteractionContext` plus `protagonist` |
| `PublishScope` | Fields evaluated by the realm at publish (book instances) | Pure values only |
| `TypeScope` | `Var<Type, TypeScope>` type fields | Pure values only; types in scope |
| `DefinitionScope` | A `Definition`'s value | The definition's surroundings |
| `MigrationScope` | Migration inputs ([migrations.md](migrations.md)) | `old` |
| `CaptureContext` | A formula run on a player by [`Capture`](capture.md) | `protagonist`, `engine` |
| `EventContext<E>` | The condition and cancel of an [event entry](events-and-handlers.md#event-entries) | `InteractionContext` plus `event: E` |
| `ReactionScope<K, T>` | Variable reaction changes | `keys: K`, `value: Settable<T>`, `previous: T?` |

In formulas the protagonist is named `protagonist`, matching the engine neutral identity.

### Group fields

The extension picks per field whether it is evaluated per member (`Var<String, MemberContext>`, `protagonist` in scope) or once per interaction (`Var<Int, InteractionContext>`, `group` in scope, no `protagonist`). The group's type comes from how the chain was widened, through `produces`:

| Widening | `group` type in scope |
| --- | --- |
| `ContinueForGroup(islands)` | `Island` |
| `ContinueForEveryone(who)` | `Snapshot` |
| None | No `group`; only `protagonist` |

Keys fill from scope by type, so `island_bank += 50` after `ContinueForEveryone` is a panel error, and `protagonist.island.island_bank += 50` is the explicit form. Groups and widening are in [interactions.md](interactions.md).

## dynamic(): what content means to the type system

Each resource and entry type has a `dynamic()` hook. It says what its content means to the type system, through these builders:

| Builder | Says |
| --- | --- |
| `bind(T) { }` | Derive a type parameter from content |
| `scope(target) { value(name, type) }` | What one own field's formulas (or my contents) can see |
| `exports { }` | What others get when they name me |
| `produces { field(...) }` | Content shaped chain context for downstream entries |
| `stored(name, keys, value, default)` | Stored data shapes, visible without an engine |

`dynamic()` does not declare which sources must run, derived relations, capability needs, or cross resource diagnostics.

### One form for code and content

Static Kotlin declarations compile through KSP to the same builder calls as generated defaults, so the realm sees one form:

- An entry's produced context becomes a default `produces { use(T) }`.
- A Kotlin `Stored` value with `@Key` fields becomes a generated `stored(...)` call. Creator blueprints (`Variable`) use the same builder.
- `Settable` members and readers such as `quest.stage(group)` are generated from `stored()`.
- A Kotlin `Live` value becomes a generated `live(...)` call, which generates a read only reader by the same rule ([live-data.md](live-data.md#reading-a-mirror-in-a-formula)).
- Names come from types (fields, cases), `scope` and `stored`. Implementations come from static Kotlin functions:

```kotlin
fun <S : Enum> Quest<S>.progress(stage: S)
```

Content names such as quest stages are enums through `bind`.

### bind

`bind` derives a generic parameter from content. KSP generates a handle per type parameter. A bound parameter has no picker; an unbound one stays creator picked through `TypeSelection`. A bound argument is never stored: the configuration holds `ArgumentSelection.bound` for it (a new case next to `chosen` and `unfilled`), and the checked catalog resolves it through the query graph from `dynamic(resource)`, which yields `named(content(at))` and the registered `TypeDefinition`. An edit that changes the bound type reruns `dynamic()` and changes the definition behind the same id; nothing is written back, and existing `ValueAdmission` flags book instances that no longer fit the derived `V`. The engine resolves `bound` the same way at load. A derived type's id is `content(at)`, the location of the field the `bind` reads, with revision 1 (see [Members and providers](#members-and-providers)). The generated book entry type is also a live `bind`, not a publish step.

```kotlin
bind(V) {
    for ((name, variable) in variables) {
        val type = variable.type.valueOrNull() ?: continue
        field(name, type, hasDefault = variable.default != null)
    }
}
```

`dynamic()` runs over a KSP generated content view of raw data, `XDraft`, never the real entry class. Each field is a value, missing, or invalid, so a broken field only drops its own members.

### scope and exports

Scope has two directions:

- **Inward**: `scope(target) { }` always aims at one own field (`scope(::text)`) or at my contents (`scope(contents)`), never at all fields.
- **Outward**: `exports { }`, for every resource. The generated default exports its fields, `stored()` values and bound types.

Which siblings a container makes visible is the container's own code, not a fixed realm rule. The book puts `book`, its elements by name and its imports into `scope(contents)`, and exports its variables per instance. Book scope and chain context (from upstream `produces`) arrive as `scope` contributions, while `C` stays the entry's own static scope.

## Lookup order

Names resolve innermost first:

1. Lambda levels
2. The context's values (`C`)
3. Each container, innermost first: the element's own `scope(::field)`, then its page's `scope(contents)`, then its book's `scope(contents)` (which includes the book's imports)
4. Top level providers, such as `now` and `minecraft` (decided 2026-11-04); `minecraft.item.diamond` is a [domain](domains.md)

The page level holds that page's elements and the book level holds all of them, so the same page wins; otherwise two elements with one name are an ambiguity error at the use site with a quick fix that qualifies by page (`village.spawn`). Element names need no uniqueness check.

Chain records are functions on their producing entry: `produces { field("chosen", Chosen) }` on `smith_question` generates `chosen: context(entry: SmithQuestionEntry, chain: Chain) () -> Chosen`, so `smith_question.chosen.index` fills `entry` by the dot and `chain` from `C`. The short form `chosen.index` (decided 2026-11-04) walks the links backwards from the entry holding the formula. One producer fills `entry`; no producer falls through to normal lookup. Two producers, or a producer and a container element with the same name, are an ambiguity error at the use site with a quick fix that qualifies, so adding a link or an element never silently changes what a formula means. A producer that is not on every path gives a nullable record.

### Names

Any name is allowed, Kotlin style. Identifier like names (Unicode letters, digits, `_`) are written bare; anything else uses backticks:

```
`Dragon Quest`.stage
```

`Element.name` is used directly. Variable, instance and import keys need only be non blank and unique per scope level. A name in a formula that resolves to a content resource is stored as a `FormulaReference`: the text range of the name in `source` and an ordinary typed link to the target. Formula references are links like any other, so they reuse the existing machinery:

- **Rename** writes nothing. The realm alone builds the display text, `source` with each reference range replaced by the target's current `name` (the field formulas bind to, not `ResourceAppearance.label`), and sends it in the `WatchFormula` snapshot; the panel never resolves names. The next edit of the formula stores the new text.
- **Delete** follows the relation's `clear` policy, as for a content `Ref` field: the link empties, the old name stays visible in the text, and an error finding ("`bonus` was deleted") blocks publish.
- **Usages** and reruns come from the existing `Incoming` input and the query graph, with no separate index.
- **Binding** of these names uses the ids, in the realm and in the engine; name lookup by text applies only while typing, and the panel saves only the text, and the realm fills in the references while it prepares the edit, binding the names against the same working state the edit was made in, so text and references always match. A name that resolves to nothing gets no reference and shows the usual unknown name error.

Only names that resolve to content resources become references. Local names, provider functions and catalog types stay text: they are code, and renaming them is a code migration. Precedent: Airtable stores field ids in formulas and shows field names.

## Members and providers

Members on types come from code per type, like presentations: a KSP generated `XFormulaProvider`, loaded by `GeneratedProviderLoader`. Static members are plain Kotlin functions in it; the signature is the declaration and the parameters are its needs. Dynamic members come from content through `dynamic()`. Defaults are the fields.

```kotlin
// A capability declares its formula functions as an interface;
// each engine implements it (PaperPlayerFormulas), and KSP checks completeness.
class PaperPlayerFormulas : ... { ... }
```

Every named type has a `TypeDefinitionId` (type id and revision). Kotlin catalog types use `declared(uuid)` with their code revision; builtins use `qualified(namespace, name)` with revision 1; cases without their own annotation use `member(owner, name)` (see [Unions and errors](#unions-and-errors)); types declared by content use `content(at: ValueLocation)` with revision 1, where `at` is the location of the content that declares the type (a `Definition`'s `value`, a position inside a `Type` value such as `[type, result]`, a position inside a resource's type argument (`ArgumentLocation`), or the field a `bind` reads, such as a book's `variables`; `content` therefore takes a declaration location that is either a `ValueLocation` or an `ArgumentLocation`). A content type changes through publication and content migrations, never through its revision. The checked catalog takes content definitions from the query graph.

Inline types are content types too: a record or union written in a type position without a name is a full `TypeDefinition` with any representation, identified by its location, so every field keeps a required `declaration_owner`. Two inline types that look alike are different types (nominal); share one through a creator type. Expression formula text names types but cannot declare an inline type (`let x: (gold: Int) = ...`), because text has no stable location; a type field or a type argument can, because its declarations sit at paths inside a stored `Type` value. Only function types are structural and have no id.

### Standard library

The standard library is ordinary providers written in Kotlin, with `FormulaFunction`s generated by KSP like any extension's. It is not generated from `operations.yaml`: formulas have one checker and one interpreter, both in Kotlin, so there is no panel parity to protect, and the expression signature kinds (`each<T,R>`, `partial<X>`, `maybe<X>`) do not fit formula signatures.

```kotlin
operator fun Int.plus(other: Int): Int = this + other
fun <T> List<T>.sumOf(f: (T) -> Int): Int = fold(0) { total, item -> total + f(item) }
```

Stdlib providers may call the existing Kotlin portable kernels (`sdk/typewriter-api/.../expression/operations/`, for example `PortableNumberKernel`, the regex matcher) as a library where their rules matter, such as regex step budgets. Text functions (`length`, `substring`, `indexOf`, and the like) count code points, as the portable text operations do, by calling the portable kernel instead of Kotlin's UTF-16 `String` members, so a creator gets the same answer in formulas and rules. Text positions inside formula source are a separate, internal matter and count UTF-16 units (see [WatchFormula](#watchformula)). Each catalog scalar is the Kotlin type KSP maps it from, and arithmetic is checked (see [Exceptions](#exceptions)).

Units and formatting are ordinary providers through existing sugar (`5.seconds` is `val Int.seconds: Duration`, `format`). PlaceholderAPI is a provider function `context(engine: Engine) fun papi(name: String): String`, backed by a `Tick` mirror where it is used.

## Book

A `Book` is a `Resource` (v1 `LibraryModel.kt`), not an entry. It carries the variables, the instances and the imports. Decided 2026-11-05 in the layer 13 rough design.

```kotlin
data class Book<V : Record>(
    /* library, title, icon, color, tags, pages */
    override val configurations: List<Ref<Configuration<*>>> = emptyList(),
    val variables: Map<String, BookVariable> = emptyMap(),
    val instances: Var<Map<String, V>, PublishScope> = ...,
    val imports: List<Import> = emptyList(),
) : Resource, ConfigurationHolder

data class BookVariable(val type: Var<Type, TypeScope>, val default: Var<*, PublishScope>? = null)
```

### Variables

Each variable is a type with an optional default, with key rules from the existing configuration system (`BookConfiguration`). Book variables hold per instance values and per instance functions. Entries read them through `scope(contents) { value("book", V) }`:

```
text = "The ${book.town.name} board has work for you."
amount = book.reward     // context(protagonist: Protagonist) () -> Int, protagonist filled from context
```

### Instances

`Book<V : Record>` is generic and never names a concrete variables type. `V` is the record type the realm derives from `book.variables` through `bind`:

```kotlin
val instances: Var<Map<String, V>, PublishScope>
// Bounty board: BountyBoardVariables { town: Town; reward: context(protagonist: Protagonist) () -> Int }
```

Plain mode is the normal map editor whose values are real records (one field per variable, the right editor, checked by `ValueAdmission`). Formula mode generates the instances, so there is no separate formula field:

```
towns.associate { it.id to BountyBoardVariables(town = it) }
```

A book with no listed instances has one root copy with an empty path. A variable without a default must be filled by every instance, or publishing is blocked. A failing instances formula also blocks publishing.

### Copies at publish

Publishing makes one copy of every resource a book owns, per instance (decided 2026-11-05). Each copy is its own entry, so handlers, `Candidate<E>`, links, and stored data need no special code. The compiled form exists today and always has an empty path:

```
CompiledResourceKey(source = give_money, context = ["riverside"])
CompiledEdge((talk, ["riverside"]) -> (give_money, ["riverside"]))   // a link stays inside its copy
CompiledEdge((talk, ["riverside"]) -> (some_tag, []))                // a reference leaving the book keeps its target
```

- `book` in a copy reads that instance's record.
- An entry identity in stored data is source plus path, so stored data is per instance automatically.
- A variable's copy is its own identity: `bounties_done(variable = (bounties_done, ["riverside"]), protagonist = ann)`.
- A `Definition` is copied too, and is the same everywhere unless it reads `book`.
- A link from another book is not allowed. Books connect through edges (layer 31).

Instance changes follow [migrations](migrations.md#books): the map key is the instance key, and renaming one moves its stored data.

### Imports

`imports` brings other books' exports into the book's contents scope. An import is `Import(book, alias: String? = null)`, named by the book title by default. An import exposes everything the other book exports. With several instances the caller picks one like a field:

```
bounty.riverside.bounties_done > 2   // several instances
bounty.bounties_done > 2             // one instance: left out
```

### Not proven

- Picking by name needs the instance keys while checking. In formula mode, that means running the formula while editing.
- Whether copies can share bytes in the compiled file, and how much memory an engine needs. Without sharing, 200 entries in 50 towns is 10,000 records.
- A rename in formula mode looks like a remove and an add, so only the migration's question can tell.
- The path is a list, but this design only uses one segment.

## Definition

`Definition<T>` is a shared named value of any type, shared by all instances of a book:

```kotlin
data class Definition<T>(
    val name: String,
    val value: Var<T, DefinitionScope>,
) : StaticEntry
```

`T` is the resource's own type argument in its configuration, chosen with the existing type argument editor; there is no `type` field and no `bind`, so a `Definition` works before `bind` exists (layer 11). Changing the type uses the existing `PreviewTypeArgumentChange` and `PrepareTypeArgumentChange` repair preview, which shows what happens to the current value before the change is confirmed. Configuration arguments hold the authored `Type` value (`ArgumentSelection.chosen: Type`, replacing `TypeUse`), so a type argument can be a function type or an inline declaration; the checked catalog lowers it to `TypeUse` like any `Type` value. Typing a type as text (`record { gold: Int }`) is another input of the type picker that parses into a `Type` value; no formula is stored. Its `dynamic()` does `exports { use(T) }`, so it is visible by name through the book's contents scope and to other books through imports.

- **Functions**: a definition whose type is a function type. The text is the body with the parameters in scope. There is no separate function entry type.

  ```
  Definition "is_veteran" type: context(protagonist: Protagonist) () -> Boolean
  value: protagonist.quests_done >= 10
  ```

- **Creator types**: a definition whose type is `Type`. Exported `Type` values become type names in scope; record types get a constructor.

  ```
  Definition "Energy" type: Type value: record { amount: Int, since: Instant }
  Energy(amount = 3, since = now)
  ```

Copy is a plain generated function (Kotlin data class `copy`; for creator records produced like the constructor, parameters defaulting to current values).

## Unions and errors

There is no error specific mechanism. A record has one of three forms:

```
struct RecordRepresentationTemplate { fields: [FieldDeclaration] = 0; form: RecordForm = 1; }
enum RecordForm { concrete = 1; open = 2; closed: ClosedCases = 3; }
struct ClosedCases { cases: [NamedTypeTemplate] = 0; }   // declaration order
```

- **Open** (Kotlin `interface`, `abstract class`): anyone adds subtypes through `parents`, and `when` needs `else`.
- **Closed** (Kotlin `sealed`, Kotlin `enum class`, content `union`): the parent lists its cases in order; `when` is exhaustive over that list and `concreteForms` returns it. An enum is a closed union whose cases are all unit; the panel shows a dropdown for it, and `enum.cases` and `enum.from_name` work on it. `RepresentationTemplate.enumeration` and `DataValue.enum_case` are removed; an enum value is stored as `named(actual_type = Door.OPEN, unit)`.
- A case without its own `@TypewriterType` (an enum entry, an unannotated nested sealed subtype) gets `TypeId.member { owner: TypeId; name: string }`, anchored to its parent's id instead of its Kotlin name.

Unions are closed records (Kotlin sealed interfaces, creator `union` types). Values carry their concrete type (`NamedValue.actual_type`), so `is`, smart casts and `when` narrow. The polymorphic editor and `concreteForms` already handle them.

```kotlin
sealed interface NpcLocation
data class Spawned(val position: Position) : NpcLocation
data class NotSpawned(val npc: Npc) : NpcLocation
```

```
when (npc.location) {
    is Spawned(position) -> position.distance(protagonist.position) < 10
    is NotSpawned -> false
}
```

- Type text uses one keyword form per declaration: `record { gold: Int, xp: Int }`, `union { Spawned(position: Position), NotSpawned }` (an enum is `union { Open, Closed }`), `Ref<Npc>`. Bindings use `let` everywhere: `if let quest = ... { }`, `when (let loc = ...) { }`.
- Unrelated types are wrapped; there is no ad hoc `A | B`.
- An unhandled union is a panel type error with quick fixes. `when` over a closed union is exhaustive against its case list, and live checks flag it when a case is added; an open type needs `else`.
- `T?` stays the catalog nullable; `?.` and `?:` work on null.
- Several return values are named results, an inline record type declared in a type position: `record { gold: Int, xp: Int }`, read with `let (gold, xp) = ...`.

### Exceptions

Arithmetic is checked: overflow, division by zero, a non finite float result, and a narrowing conversion that does not fit (`toInt()`) fail the evaluation instead of wrapping, as in Swift and Rust debug builds. Stdlib operators use the exact JVM operations (`Math.addExact`) and the portable kernel's `finite()`. A provider that throws, a checked arithmetic failure, or hitting the recursion limit fails one evaluation:

```kotlin
sealed interface Evaluation<out T> {
    data class Value<T>(val value: T) : Evaluation<T>
    data class Failed(val at: ValueLocation, val reason: FormulaFailure) : Evaluation<Nothing>
}

sealed interface FormulaFailure {
    data class ProviderThrew(val message: String) : FormulaFailure
    data object Overflow : FormulaFailure
    data object DivisionByZero : FormulaFailure
    data object NotFinite : FormulaFailure
    data object RecursionLimit : FormulaFailure
    data object NoValue : FormulaFailure // a bare mirror read with no value; see live-data.md
}
```

| Field kind | On failure |
| --- | --- |
| Text | Shows a fallback |
| Verdicts and conditions | Count as not met |
| `Changes` | Not applied |
| Other values (`reward: Int`, records) | The step that uses the value does not run |
| A pure formula the realm evaluates (a `Definition`) | Error finding that blocks publish, since the engine would fail the same way |

The engine reports every failure with its location so the panel can show it.

## Type checking

Checking is local and bidirectional, as in Kotlin, Swift and TypeScript:

- The field's `Var<T>` pushes the expected type down into the formula. Function typed fields check their body against the result type with the parameters in scope.
- Expressions infer their type up: `let needed = 5 - x` is `Int`.
- Generics are solved per call from the arguments plus the expected type; lambda parameters come from the function's parameter types.

Generic provider signatures are the checker's internal Kotlin model in the shared formula interpreter, never a contract. The checker has its own type form, `TypeUse` plus inference variables (`FormulaType`), and each provider function becomes a KSP generated `FormulaFunction` (name, type parameters with bounds, context parameters with the receiver first, parameters, defaulted parameter names, result, and an `invoke` that calls the Kotlin function). A `where` clause is extra bounds. A call unifies the context and argument types to solve the type parameters; the panel only receives closed results (`result_type: TypeUse`, diagnostics, hover and completion text with type parameters filled in), and an unsolved variable is a "cannot infer" diagnostic. Function types stay non generic, as in Kotlin. In provider signatures KSP names a single unnamed function type parameter `it` and rejects unnamed ones when there are two or more.

Name rules:

- **Fields are functions.** A record field is a function with no normal parameters whose first context parameter is the record: `name` on `Npc` is `name: context(npc: Npc) () -> String`. KSP types and content records both generate them.
- **Calling versus referring is decided by the expected type.** Where a function type is expected, a name is the function value (`members.sumOf(book.reward)`); elsewhere it is a call with context filled from scope (`book.reward` in an `Int` field). There is no `::` syntax. `members.filter(.is_veteran)` is shorthand for `{ it.is_veteran }`.
- **Overloads:** among same named functions the most specific context type wins (`distance(npc: Npc)` over `distance(entity: Entity)`); a tie is an ambiguity error with a quick fix. A generated function and a provider with the same context type stay the Open provider override question.
- **Domains:** after real members, any name on a `Domain<T>` calls `T`'s constructor with that name and records the use for the domain check ([domains.md](domains.md)). The checker reads no game data, so the call is pure and engines bind it without `KnownIds`.
- **Type names:** catalog types by display name, content types by definition name through scope; scope hides the catalog; two catalog types with one name are an ambiguity error, qualified by extension (`citizens.Npc`). Scalars use Kotlin names (`Int`, `Long`, `Float`, `Double`, `Decimal`, `String`, `Boolean`, `Instant`, `Duration`) mapped to `ScalarKind`; the width table belongs to the interpreter value model.

There is no global inference, so errors stay local. Annotations are optional: `let x: Decimal = ...`. Checking runs as `check(formula)` in the query graph and is part of the formula interpreter that the realm and engines share.

## Live editing

### Query graph

The realm runs `dynamic()` and formula checks as a query graph with early cutoff, like rust-analyzer's Salsa, on the shared `TrackedGraph` (see [Interpreter](#interpreter)):

```
draft(resource) → dynamic(resource) outputs → scopeAt(field) → check(formula)
```

- Reads inside `dynamic()` (`ref.resolve()`, field reads) are recorded automatically. Realm checks and searches use the same graph, and stored reads (type plus partial key) are inputs too: a stored commit reruns what read it ([closed-beta-roadmap.md](closed-beta-roadmap.md), Decided).
- An edit reruns only what read the change.
- A rerun whose output equals the previous one stops propagation.
- Cycles (A binds from B's exports, B from A's) are detected while running: both get an error and an error type; everything else keeps working.

Shape:

- **Inputs** come from the installed `AuthoringView`: `Resource(id) -> AuthoringRecord?`, `ResourceIds`, `Links(resource)`, and `Catalog`.
- **Commits set inputs** where views are installed: `AuthoringViewStore.install` applies the same `AuthoringViewDelta` (upserted resources, removed resources, catalog lease) to the graph, so a commit needs no separate report of changed inputs. A full reload (`views.invalidate`) sets every input again; early cutoff keeps that cheap.
- **Derived queries:** each `InputIdentity` kind is a query, plus `checkRun(instance) -> FindingSet`, `dynamic`, `scopeAt` and `check`. `CapturedAuthoringReads` keeps its API; each read is a query call, and it still records `EditExpectation`s for the commit guard.
- **Revision:** one per view install.
- **Finding currency:** a finding is current when its query is verified at the latest revision. This replaces the expectation comparison in `EditorUpdatePublisher`.
- **Publication** accepts when every check is verified at revision R and the captured view is R; otherwise it answers `RetryRequired`.
- **`WatchFormula` overlay:** `graph.fork(working: OperationWorkingContext)` takes the panel's existing working context (saved observation plus unsaved upserts and removals, `resource_operations.skir`) and reuses base results whose inputs exclude the overlaid resources, like the staged view. On a new revision the overlay is applied to the latest saved view; only a saved change to an overlaid resource is a `stale_observation_error`.
- **Cancellation:** a new revision cancels running queries; each query call checks the revision and stops when stale.
- **Memory:** `checkRun` and `dynamic` results stay; other results are LRU bounded.

The engine runs every `dynamic()` once at load, in dependency order, with the same code and no tracking.

Compiled content carries each formula in its stored form (`Formula(source, references)` inside the `Var`), not a bound tree. At load the engine parses, binds and checks it with the same `runtime/formula` code against the published content and its catalog, the inputs the realm checked at publish, and caches the result. A formula that fails to bind at load is a load error; the publish checks make that unreachable in normal operation.

### WatchFormula

The panel edits formulas language server style. The realm answers through a live subscription built from the existing search pieces (`search.skir`: a retained job, a snapshot stream, reusing the subscription id cancels the previous job), except that it never reaches `ready`: a `TrackedGraph` observer sends a new snapshot whenever the result changes, for example after another creator renames `base_reward`, until the panel replaces or cancels it. Unsaved panel edits arrive as the existing `OperationWorkingContext`:

```skir
// editor/v1/formula.skir, next to search.skir
method WatchFormula(struct {
  subscription_id: string;          // one per open editor, reused on every keystroke
  input_revision: int64;            // rises per keystroke; echoed back
  location: ValueLocation;
  source: string;
  caret: int32?;                    // UTF-16; completions only when set
  working: OperationWorkingContext; // unsaved panel edits
  catalog: CatalogGeneration;
}) streams FormulaUpdate

enum FormulaUpdate {
  snapshot: FormulaSnapshot;
  stale_observation_error: StaleAuthoringObservation;
  unavailable_error: [Diagnostic];
  internal_error: InternalError;
}

struct FormulaSnapshot {
  subscription_id: string;
  input_revision: int64;            // the panel drops snapshots older than its latest keystroke
  display: string;
  references: [FormulaReference];
  diagnostics: [Diagnostic];        // TextSpan details
  result_type: TypeUse?;
  value: DataValue?;                // pure formulas only
  completions: [FormulaCompletion];
}

struct FormulaCompletion {
  label: string;
  kind: enum { value, function, type, keyword, local };
  detail: string;                   // the type, such as "Int"
  insert: string;
  replace: TextSpan;                // the text the completion replaces
}

method FormulaHover(struct { subscription_id: string; position: int32; })
  -> struct { text: string; span: TextSpan; }?
method CancelFormulaWatch(struct { subscription_id: string; })
```

Hover is a separate call answered from the subscription's computed state, because the pointer moves far more often than the text changes (the language server protocol separates them too). The snapshot carries no references for saving; the realm fills those while preparing the save.

Snapshots are computed by `scopeAt` and `check` over the unapplied text. All text positions in formulas (`FormulaReference.at`, the cursor, diagnostic and completion ranges) count UTF-16 code units, the native string index of Dart and Kotlin and the language server protocol default. `display` is the text with current names and `references` are its ranges, used for highlighting and saved with the text; until the first snapshot arrives the editor shows the stored `source`. A deleted target keeps its old name, underlined with its error. For a pure formula the snapshot also carries its value, evaluated through the same query graph (`total` shows `= 70`); a stored or live formula shows that it needs a player until live values per protagonist exist. There is one checker, in Kotlin. The panel stays thin and may filter the last completion list locally while the next snapshot arrives.

### Formula checks

Formula findings go through the existing `RealmCheckProvider` and are computed through the query graph. Errors block publication: type errors (unhandled union kinds, non exhaustive `when`), formulas that need engine or stored data in realm run fields, keys not fillable from scope, and `dynamic()` cycles. The full checks list is in [live-data.md](live-data.md).

Errors keep one type, `Diagnostic`, for saved findings (`FindingSet`) and live editor snapshots alike. A diagnostic points at a field plus optional typed detail that the field's editor understands:

```diff
+ struct DiagnosticAnchor {
+   at: ValueLocation = 0;
+   detail: DataValue? = 1;     // a value of a declared type, such as TextSpan
+ }
  struct Diagnostic {
    ...
-   primary: ValueLocation? = 5;
-   related: [ValueLocation] = 6;
+   primary: DiagnosticAnchor? = 5;
+   related: [DiagnosticAnchor] = 6;
  }
```

```kotlin
@TypewriterType(id = TEXT_SPAN_TYPE_ID)
data class TextSpan(val start: Int, val end: Int)   // UTF-16 units

report(at = total.value, detail = TextSpan(14, 19), message = "`bonus` is unknown")
```

- An editor renders the detail types it knows (the formula editor underlines a `TextSpan`) and highlights the whole field for any other, which is the behavior without detail.
- Detail types are ordinary declared types, so later layers and extensions add their own (a moment on a cinematic track, a corner of a region) without changing the core contract. A closed `enum DiagnosticDetail` was rejected for that reason. Precedent: the language server protocol's `data` and SARIF's property bag, both untyped.
- While a formula editor is open, its live diagnostics replace the saved findings for that field; the check list and closed fields show saved findings, and the next check run after a save makes them agree.

## Syntax summary

The base is Kotlin. The full tour, with examples, is in [../vision/formulas.md](../vision/formulas.md). Summary:

| Area | Rule |
| --- | --- |
| Control flow | Every construct is an expression (`if`, `when`, blocks); a block's value is its last line |
| Conditionals | `if (c) a else b` and the ternary `c ? a : b`; `?.` and `?:` stay single tokens |
| Bindings | `let`, `if let`, `let else`; Rust style shadowing (a new `let` hides the old one from its line on, the type may change) |
| Patterns | Destructuring and guards in `when`: `is Money(amount) if amount > 100 ->` |
| Shorthand | `members.filter(.is_veteran).sumOf(.coins)` |
| Collections | `[riverside, hilltop]`, `[sword: 50]`, `10..49`, `in`; indexing returns nullable |
| Calls | Named and default arguments, trailing lambdas; no `with` (no member scope) |
| Functions | Local functions `let double(x: Int) = x * 2` (recursion works); lambdas `{ x -> }`, `it`, `_`, `{ (k, v) -> }` |
| Comparisons | Chained `0 < x < 10`; `==` is structural only |
| Logic | `&&`, `\|\|`, `!` plus `and`, `or`, `not` |
| Change lines | `=`, `+=`, `-=`, `*=`, `?=` (set if absent), `require(cond, msg)` |
| Loops | None; ranges, `map`, `forEach` (returns all changes in change fields), `fold` |
| Literals | Raw strings `"""..."""`; numbers `1_000`, `0.5`, `1e3`, typed by context |
| Lines | A newline ends a line; `;` optional; comments `//`, `/* */`, doc comments `///` shown in autocomplete and hover |
| Not included | `!!`, `x with { }` |

Keywords: `let`, `record`, `union`, `context`, `if`, `else`, `when`, `is`, `in`, `as?`, `and`, `or`, `not`, `true`, `false`, `null`.

## Text templates

A string template is sugar for a function call, and the expected type picks which `template` provider applies:

```
"a${x}b"   means   template(listOf("a", x.interpolate(), "b"))
"${coins:#,###}"   means   coins.format("#,###").interpolate()
```

- The stdlib provides `template` for `String`; the Minecraft capability provides it for `RichText` (MiniMessage).
- `interpolate()` providers decide how a value enters text. `RichText` escapes tags by default, so player input cannot inject tags; `RichText.interpolate()` keeps them. Types can render richly (`Item.interpolate()` with hover).
- The template editor highlights holes, renders MiniMessage, and runs `WatchFormula` inside holes.

`RichText` is a MiniMessage string, and Adventure handles it at the edges (decided 2026-11-05). Adventure runs without Paper, and engines on other platforms have it too, so a typed tree of our own would add code without adding support. New text features arrive with a library bump. This is the one deliberate exception to [owning game data as typed records](minecraft-types.md#components): the string is the readable language creators write, like a formula, and is not tied to a game version.

```kotlin
@TypewriterType(id = RICH_TEXT_TYPE_ID)
@JvmInline @Serializable
value class RichText(val text: String)

object RichTextBridge : Bridge<RichText, Component> {
    override fun toPlatform(value: RichText) = miniMessage.deserialize(value.text)
    override fun fromPlatform(platform: Component) = RichText(miniMessage.serialize(platform))
}
```

- **Tested on MiniMessage 4.20, without Paper:** 20 of 20 kinds of text survived the trip to a string and back, including click, hover, translations, key binds, scores, selectors, NBT, shadow, and font. A gradient stays a gradient. Player text is escaped, so it cannot inject tags. One parse took 11 microseconds.
- **Library versions differ by release:** Paper bundles Adventure 4.20 on 1.21.4, 4.26 on 1.21.11 and 26.1.2, and 5.1 on 26.2. The stored string does not depend on them, and each release compiles its own [bridges](generated-types.md#supported-versions).
- **A newer tag on an older server** shows as plain text: `<sprite:x>` stayed literal in the test.
- **Not proven:** a hover item with components may depend on the game version. The panel preview is not designed; turning the string into the existing `RichTextContent` runs on the server avoids a parser in Dart.

Entry authors only declare the field:

```kotlin
val text: Var<RichText, MemberContext>
```

Text the protagonist sees is live: a display derive reads it, so it follows stored data and hot publish.

## Where formulas run

The same rule as handlers: the types a function touches decide its kind.

| Kind | Touches | Can run on |
| --- | --- | --- |
| Pure | Plain values, content | Realm and engines |
| Stored | Stored values | Anywhere stored data is reachable |
| Live | Mirrors, through their [readers](live-data.md#reading-a-mirror-in-a-formula) | Any engine; a value held elsewhere crosses |

Only context parameters reach stored or live data: identities such as `protagonist` and `engine: Engine` (the neutral identity of the server a formula runs on) carry the stored and live members. A provider that reads stored or live data without such an input declares it as a context parameter (`context(engine: Engine) fun papi(name: String)`); KSP cannot see function bodies, so this is a declaration it trusts. A formula's kind therefore follows from its context: `Var<Map<String, V>, PublishScope>` and `Var<Type, TypeScope>` provide no context parameters, so their formulas are pure by construction, and `Var<String, MemberContext>` can reach anything its context provides. A function type needs no kind marker. KSP still reads each provider's kind from its signature, and the realm computes a formula's kind while typing to decide where it can run. The realm can evaluate formulas that need no engine type.

### What a formula reads

A formula is identified by what it reads, not by who asked (decided 2026-11-04). This is memoization on formulas and parts of formulas, and it matches mirrors and derives, which are identified by their keys and parameters.

```kotlin
// Computed by the checker at publish, for each formula and part.
data class FormulaReads(
    val context: Set<ContextParameter>, // protagonist, engine, considered
    val providers: Set<ProviderId>,     // coins, health, now, random
)

val kind = strongest(reads.providers)
val key = FormulaKey(part, valuesOf(reads.context))
```

- **Shared by construction.** `now.hour >= 20` is computed once for 500 players, the same text in three entries is one memo per subject, and `is_veteran(protagonist)` is one memo per protagonist across all its callers. `random` reads its run, so it stays per subject with no rule of its own.
- **Where a memo sits.** At a whole formula, at a `Definition` call, and at the largest part that drops a context read. In `protagonist in considered.sortedBy { it.protagonist.coins }.take(10)`, the sorted part has one memo per audience and each player has a tiny combine. A single combine is not tracked, because tracking it costs more than redoing it.
- **Known at publish.** Every formula is published content, so the checker knows what each one can read. A branch or a function value counts as the union of what it can read. Which keys a list reads (`it.protagonist.coins`) follows from the list's values at run time, and the graph tracks those.
- **What follows from it.** A formula's kind, what rechecks on a timer (only what reads `now`), what is polled (`papi`, only where read), and which writers run before a chain.
- **A provider's signature is its contract** (decided 2026-11-04). KSP cannot see a body, so a Kotlin provider that reads something its signature does not declare is memoized on what it declares and may run only once. That is a bug in the extension, not something core guards against.

### Interpreter

The formula interpreter lives in a new `formula` module (`runtime/formula`) that the realm and `engine-core` both depend on; it depends on `typewriter-api`. It parses text, checks, binds names, runs `dynamic()`, evaluates, and caches outcomes. Types KSP generates into extension code (`FormulaFunction`, `FormulaType`, `FormulaParameter`, `TypeVariable`) live in `typewriter-api`; `Var`, `Formula` and `FormulaReference` live in `typewriter-contracts`. Read tracking is one component in this module, `TrackedGraph`: inputs, memoized queries that record their reads, early cutoff, revisions, `fork` overlays, and observers that, after each batch of input changes, recheck watched queries and report changed results. The realm uses it as the query graph (inputs from `AuthoringViewDelta`, results pulled); the engine sets inputs from `Changed<X>` and hot publish and observes watched formulas to update their `Watched<T>` mirrors, as Jane Street's Incremental does with observers. On the engine only the worker's recheck touches the graph, once per tick, so it needs no locks ([live-data.md](live-data.md#formula-changes)). Engine memos are kept for watched results and LRU bounded otherwise. The realm part is built in layer 1 and its observers in layer 2 (`WatchFormula`); engine inputs and engine observers come with layers 6 to 8.

Values during evaluation are plain Kotlin values, so a `FormulaFunction.invoke` calls the provider without conversion: catalog scalars use the Kotlin type KSP maps them from (`Int` is `kotlin.Int`, `Decimal` is `BigDecimal`), Kotlin catalog types are instances of their class (an enum case is its constant), `null` is `null`, and functions are closures. Content types have no Kotlin class, so they are `ContentValue` instances (a record carries its `TypeId` and its fields by name, a case its `TypeId` and payload). The realm reads stored `DataValue` into these values with the same reader the engine uses for compiled content. Creating the module is a build change the layer 1 build asks for. How evaluation records its reads, which change signal each read kind has, and the `Watched<T>` mirror are in [live-data.md](live-data.md#formula-changes).

## Time and randomness

`now` is fixed per evaluation. In a `Changes` field the engine's prediction uses the engine's clock, and the realm's evaluation uses the realm's clock, also on each retry after a conflict. The committed value replaces the predicted one, so the stored time is the realm's ([stored-data.md](stored-data.md#transactions)).

`random(...)` has one rule (decided 2026-11-04):

```
seed   = (run, place)   // place: the field's value_location, so list items differ
random = the next number from one stream per evaluation
```

So rechecking a field gives the same result, and two calls in one formula differ. Only the run differs per context:

| Where | Run | Rolls again |
| --- | --- | --- |
| Chain field (`InteractionContext`) | The chain's seed record | New chain |
| Member field (`MemberContext`) | The seed record plus the member | Per member |
| `Changes` field, also a reaction's `changes` and `schedule` | The write's id | Every write |
| `Candidate` field | The event's `OccurrenceId` | Every event |
| Function definition | The caller's stream | As the caller |
| Watched formula | The subject | Per subject, then never |
| `PublishScope`, `TypeScope`, a constant `Definition` | None: place only | Never |

- **A fresh roll on purpose** is stored through a `Changes` field. Each write rolls again, also in a looping chain.
- **Prediction and decision agree.** The engine's prediction and the realm's evaluation, with its retries, share one write id. A write the realm starts itself gets its id from the realm, so each key of an `Every` rolls its own number. A crash before the commit shows nothing, so a new roll there is harmless.
- **Engines agree.** One event on several engines has one `OccurrenceId`, so their `Candidate` fields roll alike.
- **Places that never roll again** allow `random`, and the realm reports a warning finding on the formula. The roll is stable across publishes, and the preview shows the real value.
- **Kotlin** transaction functions use `tx.random`, seeded like a `Changes` field. Its exact form is for the layer 7 plan, as is confirming that every local event has an `OccurrenceId` from its `Sink`.
- **Not for secrets.** The numbers are predictable from the seed.

## Formula starts

A formula can start a chain: when a condition turns true, or whenever a formula's output changes. Both are `Changed<Watched<T>>` ([live-data.md](live-data.md#formula-changes)).

## Open

- `XDraft` modeling of invalid values: confirmed by the roadmap survey (`Availability`), but its fit for `dynamic()` is not yet verified in code.
- Provider override details: whether a same name function replaces a generated member and how `hidden` hides one.
- Placed generated book entries as instances (layer 31).
- Where cross resource diagnostics from `dynamic()` are produced.
- Editor design for function type parameters in the panel.
- Live formula values per protagonist in the panel (vision item) have no design yet.
