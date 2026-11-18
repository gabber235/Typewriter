package com.typewritermc.formula

/**
 * Declares an object whose public functions and properties are formula functions. Codegen emits one provider that
 * lists them, with signatures in the catalog's type forms, so the realm checks and runs what the Kotlin code declares.
 * A receiver becomes the function's first context slot, named `this`.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterFormulaProvider

/** The name formulas use for a function or property, when a Kotlin member of the receiver would hide that name. */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterFormulaName(
    val name: String,
)
