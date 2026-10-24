package com.typewritermc.dsl

/**
 * Marks Typewriter builder scopes. Inside a marked scope, members of an enclosing marked scope need an explicit
 * receiver, so a call such as `label` inside `numericInput { }` cannot silently configure the enclosing control.
 *
 * Kotlin treats a receiver as marked when its type or any supertype is marked, so marking the root scopes (Control,
 * the input and collection appearance scopes, configuration Field, and the resource operation scopes) covers every
 * control, input scope, configuration field scope and generated operations scope. Layout is deliberately unmarked:
 * typed presentation scopes extend it, and their field accessors must stay usable inside nested layout bodies such as
 * `row { x { } }`.
 */
@DslMarker
@Target(AnnotationTarget.CLASS)
annotation class TypewriterDsl
