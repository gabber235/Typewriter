package com.typewritermc.types

import kotlin.reflect.KClass

/** Selects canonical models for generated expression schemas without registering authored types. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterReadModels(
    vararg val types: KClass<*>,
)
