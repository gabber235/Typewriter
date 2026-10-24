# Services guidance

## Extension functions and properties

Prefer extension functions and properties when behavior has a clear primary receiver. Make operations discoverable on the value they act on, especially when its type is generated, externally owned, or should remain a small domain model. Keep extensions near the capability they serve.

Use extension properties for cheap derived values without side effects. Use functions for actions, expensive computations, and I/O. Keep intrinsic behavior that needs private state or polymorphic dispatch on the owning type. Use top level functions for factories, entry points, and coordination with no natural receiver.

## Context parameters

Prefer [context parameters](https://kotlinlang.org/docs/context-parameters.html) for capabilities shared by operations within a scope, such as authored reads, edits, runtime scopes, and telemetry. They are Kotlin's successor to context receivers. The shared services conventions already enable them; use the current `context(name: Type)` syntax.

Combine context parameters with extension functions and properties so the receiver identifies the value being operated on and the context declares the required capabilities. Name a context parameter when its value is used directly; use `_` when it only supplies context to other calls. Keep operation inputs as ordinary parameters and give persistent dependencies an explicit owner. Establish context at clear boundaries so required capabilities and their lifetimes remain understandable.

## Idiomatic Kotlin

Use Kotlin's language features to express the model and simplify calling code:

- Prefer `val` and immutable models. Use data classes for values, sealed classes or interfaces for closed alternatives, and exhaustive `when` expressions to handle them.
- Use value classes for distinct identifiers and other domain values when their constraints fit. Preserve nullability in types and use safe calls, smart casts, and explicit handling of absent values.
- Use named arguments and default parameters to make calls clear without repetitive overloads.
- Use receiver lambdas and `@DslMarker` for structured DSLs, delegation for shared implementations, and inline functions with reified type parameters when they simplify typed APIs.
- Reuse standard library collection operations and scope functions where they make transformations clearer. Keep receiver nesting and control flow easy to follow.
- Use suspending functions and structured concurrency for asynchronous work. Give coroutine scopes a lifecycle owner and preserve cancellation.

Choose features because they improve clarity, correctness, or developer experience. Follow the Kotlin version and compiler capabilities configured by the project.

## Code generation

Prefer code generation when it removes meaningful boilerplate or improves developer experience. This includes typed accessors, DSL helpers, adapters, registrations, metadata, and serialization. Better completion, stronger type checking, and fewer manual synchronization points are valid reasons to generate APIs.

Extend the existing generation mechanisms before introducing another one. Kotlin source processing uses KSP and KotlinPoet in `sdk/typewriter-codegen`; shared protocol declarations live in `../skir-src`. Use Kotlin's built in mechanisms where they already express the behavior cleanly.

Keep declarations as the source of truth and generated behavior understandable from them. Make generation deterministic, reproducible, and inspectable, with useful diagnostics tied to the declaration that needs fixing. Update generators or source declarations instead of editing generated output manually.

When changing a generated API, update its source, generator, and affected consumers together. Regenerate affected outputs and verify representative calling code compiles. Cover meaningful generation guarantees, including rejected declarations and their diagnostics, in the existing generator test setup.
