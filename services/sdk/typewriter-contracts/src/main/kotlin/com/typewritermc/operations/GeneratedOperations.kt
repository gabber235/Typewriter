package com.typewritermc.operations

import kotlin.reflect.KClass

/** Lets KSP recognize a generated contract in source and dependency artifacts. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class GeneratedOperations(
    val resource: KClass<*>,
    val nativeParameters: Int,
)
