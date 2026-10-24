package com.typewritermc.presentation

/** Marks a top level collection projection function that codegen publishes through a generated provider. */
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterCollectionProjection
