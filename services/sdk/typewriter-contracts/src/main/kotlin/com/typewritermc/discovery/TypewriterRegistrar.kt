package com.typewritermc.discovery

/**
 * Declares a runtime registrar class. Codegen emits its provider and index row; [id] must satisfy
 * [RuntimeRegistrarId], and at least one of [realm] and [execution] selects the domains it registers in.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class TypewriterRegistrar(
    val id: String,
    val realm: Boolean = false,
    val execution: Boolean = true,
)
