---
title: Typed Data and Editor Protocol
description: Semantics for nominal editor types, exact values, catalogues, conversions, bindings, presentations, and realm actions.
badge: experimental
---

:::experimental[Experimental contract]
The editor contract is an experimental bounded context. Its Skir identifiers are stable within the current baseline, but the baseline may still be replaced before the protocol becomes stable.
:::

The typed editor separates semantic types, concrete values, catalogue resources, bindings, presentation, and actions. A presentation can choose how a value is edited, but it cannot redefine which values are valid. A realm can publish new nominal types and presentations without adding Dart code to the panel.

## Identity and exact applications

`TypeId` is either a shared builtin identity or a qualified realm identity. A qualified identity contains a namespace and local name. The identity remains stable when the declaration evolves.

`ResolvedTypeRef` identifies one positive revision and supplies every generic argument. Persisted polymorphic values, conversion endpoints, catalogue queries, and root envelopes use resolved references. The panel never silently replaces one revision with another.

A type declaration is one of three kinds:

- **Concrete**: Values may carry this type as their exact runtime identity.
- **Open abstract**: Any valid transitive descendant may provide a concrete value, including descendants supplied by another extension.
- **Sealed abstract**: Only descendants owned by the declaring source may provide concrete values.

Type declarations contain parameters, direct parents, a representation, and presentation references. Named presentation references do not affect validation or assignability.

## Structural expressions

Structural expressions describe representations and constraints. The initial set includes unit, boolean, string, bytes, signed and unsigned integer widths, binary floats, exact decimals, timestamps, durations, enums, lists, typed maps, records, parameters, and named exact applications.

Structural reference and union expressions do not exist. `Ref<T>` is a nominal generic type. Polymorphism uses abstract nominal declarations and exact concrete tags.

Semantic identifiers are named string backed types. This preserves their meaning without requiring a special identifier primitive.

`EnumType` contains a value type and a nonempty set of unique canonical typed values. Validation rejects a canonical value that does not satisfy the value type and rejects duplicates after structural value comparison.

Color and icon values are standard named types. Color uses a constrained numeric representation. `Icon` is a sealed abstract nominal type whose concrete variants are `IconifyIcon` and `SvgIcon`. Each exact concrete icon tag retains its own validation and default presentation.

## Complete records and options

Every declared record field is present in every valid record value. Record fields do not carry a required flag. A missing field is invalid, even when the field has an initializer.

Optionality uses the bootstrap nominal family `Option<T>`, `Some<T>`, and `None<T>`. `Option<T>` is sealed abstract. `Some<T>` stores one `T`. `None<T>` represents the absence of a value without null or a missing record key.

Initializers belong to field or creation definitions. They help construct a valid value but do not alter the accepted value set. Generated values use the same creation boundary.

Null is not a value. Decoding explicit null produces a structured diagnostic.

## Inheritance and refinement

Multiple inheritance is constraint intersection. Parents do not have precedence.

A child may add fields or tighten constraints. It may not remove a required representation component, weaken a bound, widen an enum, or introduce an incompatible representation. The registry rejects conflicting parents, invalid cycles, weakened declarations, incompatible generic applications, and empty constraint intersections.

The registry retains direct parents separately from transitive ancestors. This gives inheritance upcasts one canonical route in the conversion graph.

## Generics and variance

Parameters are invariant unless declared covariant or contravariant. The registry validates arity, bounds, substitution, parameter use, variance position, and dependent bounds.

Inference unifies the selected concrete type with declared bounds and parent applications. Dependent arguments are solved together. Once inference succeeds, the exact application is stored. Later changes require an explicit conversion to another exact application.

This supports patterns such as `Var<T>`, `ConstVar<T>`, and a backed variable whose entry type determines both a value type and associated data type. Presentations can inspect generic bounds when offering choices, while stored values retain the inferred exact arguments.

## Typed values and wire mapping

Scalar values use concrete Dart payloads. Integers use `BigInt`, bytes use `Uint8List`, timestamps use UTC `DateTime`, and durations use `Duration`.

The Skir duration value wraps the shared `kernel/v1/Duration` record under the field named `duration`. The panel accepts only values that can be represented at the wire precision without silent loss.

Lists, maps, and records use dedicated immutable containers. Maps use typed entry collections, so keys are not restricted to strings.

Nominal tags appear only at polymorphic boundaries. A polymorphic value carries a `ResolvedTypeRef` for its concrete type and a payload matching that concrete representation. Concrete nominal values used outside a polymorphic boundary serialize as their representation.

`TypedValueEnvelope` contains an exact root type and one typed root value. It does not carry catalogue data, protocol versions, capability requirements, or evaluation budgets.

## Relations and projections

The runtime exposes distinct relations:

- **Equivalence**: Both expressions accept the same values and have identical nominal requirements.
- **Subtype**: Every value accepted by the source is accepted by the target.
- **Assignability**: A source value may be stored in the target without a fallible conversion.
- **Validation**: One concrete value satisfies one expression.
- **Common editable projection**: Multiple selected values expose the structurally shared editable surface.

A common editable projection is ephemeral. Persisted application roots remain nominal even when a multi selection editor temporarily exposes a structural intersection.

## Conversions

Conversions form a directed graph between exact applications. Each definition declares safety, fallibility, locality, cost, and a portable rule.

Automatic conversion considers only local, lossless edges. It selects one unique lowest cost path. Equal lowest cost routes produce an ambiguity diagnostic.

Direct inheritance upcasts have zero cost. Downcasts require explicit validation. Revision migrations use the same graph.

Portable rules include scalar conversion, record projection, record construction, collection mapping, polymorphic matching, and composition. Realm locality is represented without a capability identifier. Production realm conversion execution is unavailable in this delivery and returns a structured diagnostic.

## Structured paths and bindings

`DataPath` contains sealed field, index, map key, and concrete type segments. Field names and map keys are never parsed from dotted strings.

Path resolution returns a typed binding or structured diagnostics. Invalid paths, missing complete record fields, out of bounds indexes, inactive concrete types, and incompatible map keys remain distinct failures.

`BindingId` wraps a nonnegative integer. It cannot be confused with a revision, field index, or arbitrary string.

Bindings expose loading, conflict, invalid, and ready states. Missing complete record fields are invalid rather than absent. Mutations return applied, conflict, or invalid outcomes. Multi selection validates every target before changing any target.

## Element definitions

`ElementDefinition` contains presentation metadata for an entry or cue element. Its resolved nominal root type is its identity. The element model does not repeat type representations, generic restrictions, inheritance, path behavior, tags, or catalogue state.

The panel resolves an element root through the active realm catalogue before creating an inspector selection. A valid root must be concrete and must resolve to a record representation. Unknown roots, abstract roots, incompatible representations, and invalid icon metadata produce structured diagnostics. Entry and cue selections remain loading while the focused catalogue request is incomplete.

Element icons use the `IconValue` union. An icon is either an Iconify identity or sanitized SVG content. Invalid SVG content renders a safe fallback and never reaches the SVG renderer.

`PageType` controls layout only. A replaceable panel policy maps each layout to one abstract nominal element family. Pickers and drag targets request catalogue subtype results and accept only the returned concrete descendants. An unavailable or incomplete subtype result rejects the mutation safely.

## Catalogue lifecycle

Shared builtin definitions live in the panel. Realm definitions, presentations, conversions, subtype results, and realm action definitions are fetched lazily.

The unary catalogue query accepts an expected generation and focused item requests. It returns only requested resources, subtype results, and partial diagnostics. It never sends a full catalogue with every value.

The panel partitions cached resources by organization and realm. Cache state is cleared when navigation leaves the realm, the connection closes, the provider is disposed, identity changes, a generation mismatch occurs, or the realm publishes an invalidation.

The catalogue watch reports an initial generation and publishes unconditional invalidation events. An invalidation increments a local epoch and clears the realm partition even when the generation and type revisions are unchanged. Responses started under an older local epoch are discarded.

A generation mismatch clears the partition and retries once. A second mismatch becomes an unavailable diagnostic.

The production catalogue source is intentionally unavailable until extension discovery is implemented. Fake sources exercise the complete transport and cache lifecycle now.

## Presentation definitions

Presentation definitions are separate catalogue resources. Every definition has a stable `PresentationId`, a target type expression, and a presentation root.

A nominal declaration may select one default presentation and any number of named presentations. Generic presentation targets may reference the declaration parameters. Exact arguments are substituted before validation and rendering.

Presentation selection follows this order:

1. Explicit composition at the use site.
2. An explicitly selected named presentation.
3. The nominal declaration default.
4. The panel generated structural default.

The default delegation element applies this resolution to another binding. Recursive delegation produces a localized diagnostic instead of disabling valid siblings.

Plain strings use multiline editing by default. The builtin named single line presentation provides the inverse behavior when selected explicitly.

Maps may provide independent presentations for keys and values. Lists, maps, records, enums, timestamps, durations, bytes, colors, icons, and polymorphic values use dedicated controls rather than a generic composite control.

Conditional elements own visibility. Presentation properties retain enabled and read only behavior. Expansion belongs to semantic headers. Tabs use `initiallySelectedTabId`. Spacer dimensions and slider divisions are typed expressions.

### Sections

`SectionElement` is the single contained layout surface. Its child provides content, while the surrounding `PresentationNode` header optionally provides a title, description, actions, and collapse behavior. This keeps visual containment independent from semantic header behavior and removes separate card and collapsible layout variants.

A section may omit its border, apply one `PresentationBorderSide` to every side with `all`, or configure `top`, `start`, `end`, and `bottom` independently with `sides`. Every present side has its own positive finite width and optional typed color expression. An omitted color uses the theme outline color. Logical `start` and `end` sides follow text direction.

### Semantic headers

Every `PresentationNode` may declare `PresentationHeader` chrome. A header may provide typed title and description expressions, an optional initial expansion state, and typed actions. A null expansion state means the header stays inline. A true or false value makes it collapsible and selects its initial state.

Header identity combines the node identity with its canonical binding. Alias resolution happens before comparison. Headers reached through typed fields, scoped bindings, the selected conditional branch, repeated item scopes, and default presentation delegation therefore compose when they describe the same value. The outer title, description, and expansion setting win. Inner metadata fills missing values. An outer action replaces an inner action with the same qualified `HeaderActionId`. Headers for distinct bindings remain nested.

Expansion state belongs to the panel renderer session. It survives value updates and presentation reconstruction, while a root change clears it. Collapsed content remains mounted so focus, text selection, and child widget state are retained.

Generated nested records, lists, maps, list items, and map entries receive collapsed headers. The generated root record remains inline. Root lists and maps start expanded because their collection actions need visible chrome. An explicit composite can remain inline when it has neither header metadata nor enabled standard actions.

Lists contribute `typewriter:list.add` to their collection header. Actionable items contribute `typewriter:list.item.remove`, `typewriter:list.item.duplicate`, and one `typewriter:list.item.reorder` identity. Maps contribute `typewriter:map.add`, while actionable entries contribute `typewriter:map.entry.remove`. Record headers group content but add no mutations.

Reorder is direct manipulation. Its registered action stays pinned as a drag handle and never enters the overflow menu. Completion emits one typed local action with the canonical source item binding and the final zero based destination index. The executor derives the parent list and old index from the source. Moving to the current index succeeds without changing the binding revision.

Immediate header actions render as compact icon controls. Higher evaluated priorities remain visible longer, while equal priorities preserve declaration order. Remaining actions move into an anchored menu. Hidden actions are removed from controls and semantic registration. Disabled actions stay visible. Invalid expressions become disabled diagnostic actions without affecting valid actions or child content.

Each action selects `beforeTitle`, `afterTitle`, or `end` placement. Actions before and after the title stay pinned and preserve their evaluated priority order. End actions form the responsive action rail and move into overflow by priority when space is constrained. Reorder uses `beforeTitle`, while standard add, remove, and duplicate actions use `end`. An outer action override may replace both the behavior and placement of an inherited action with the same identity.

Visible immediate actions enter the nearest focused managed action scope. The panel maps qualified identities to concrete shortcuts. Unknown identities remain operable through pointer controls. Optional typed confirmation applies equally to direct controls, overflow commands, and keyboard invocation.

## Future annotation authoring

This delivery does not inspect, rename, translate, or migrate Kotlin annotations.

The model leaves a future authoring path without storing annotations in type expressions. A future compiler may translate semantic annotations into named types or constraints, creation annotations into initializers, and visual annotations into presentation selections or compositions.

For example, the existing multiline annotation can become unnecessary because strings default to multiline. A future single line annotation may select the builtin named presentation. Colored MiniMessage text may become a semantic named string type. Generated values may become field initializers.

These examples describe future translation only. They are not implemented by the panel, realm, module plugin, or extensions in this delivery.

## Expressions and safety

Expressions support typed literals, bindings, field access, interpolation, comparison, boolean operations, arithmetic, conditionals, collection projection, and conversions.

The panel owns fixed limits for expression depth, node count, and evaluation count. Wire data cannot increase those limits. Every expression is type checked before rendering or mutation.

Unsupported images, links, icons, rich text, and SVG data are sanitized or localized as diagnostics. Invalid bindings disable mutation only for the affected subtree.

## Actions and authority

`EditorAction` has two wrapped families. `LocalEditorAction` and `RealmEditorAction` evolve through separate Skir variant spaces.

Local actions cover value replacement, list insertion, append, removal, duplication, reorder, map insertion and removal, and concrete nominal type replacement. Presentation actions do not carry a fixed expected revision. Invocation captures the current target revision, validates the complete mutation, and then applies the optimistic update. Multi selection validates every target before changing any selected value.

Realm actions include explicit reload and extension callback variants. Callback definitions have a qualified `RealmActionId`, an exact payload type, and an optional exact result type. The panel evaluates and validates the payload before dispatch.

Production realm action execution is intentionally unavailable in this delivery. The route and result model exist, and fake sources verify dispatch. Results distinguish success, conflict, invalid input, permission denial, and unavailability.

There is no capability negotiation. Skir variant evolution and unknown variant handling define compatibility. Unknown presentation or action variants become localized diagnostics.

## Contract evolution

Every Skir type, field, method, and variant has a stable numeric identifier. Additive changes use new identifiers. Removed identifiers are never reused.

The editor bounded context does not carry a separate protocol version. Skir snapshots define the compatibility baseline. Breaking changes require a new bounded context major version after the contract becomes stable.

Generated Dart, Kotlin, and Rust outputs are mechanical contract artifacts. Business behavior remains in handwritten panel and service boundaries.

## Failure behavior

Diagnostics carry a stable code, severity, message, optional related type, structured details, and optional structured path.

Catalogue failures preserve unaffected cached resources. Presentation failures replace only the invalid subtree. Mutation failures do not partially update a multi selection. Unknown exact types, invalid generic applications, stale catalogue responses, conversion ambiguity, and recursive presentation delegation all fail explicitly.

## Delivery boundary

This delivery implements panel semantics, Skir contracts, generated outputs, catalogue transport scaffolding, invalidation, fake realm sources, and this reference.

Extension discovery, Kotlin reflection mapping, annotation translation, actual hot reload hooks, production typed value generation, production realm conversion execution, and production realm action execution remain future work. Legacy `app/`, the old module plugin, and extension declarations are not part of this implementation.
