package com.typewritermc.formula

/**
 * Declares an object whose `register` says what content means: the names its formulas see and what naming a resource
 * gives. Codegen emits its provider, which the realm collects with the code catalog like a check provider.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterDynamicProvider
