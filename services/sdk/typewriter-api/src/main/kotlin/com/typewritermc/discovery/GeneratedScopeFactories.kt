package com.typewritermc.discovery

import kotlin.reflect.KClass

/** Checks erased generated scope metadata at the factory boundary before returning its typed receiver. */
internal fun <Scope> checkedGeneratedScope(
    scope: KClass<*>,
    value: Any,
): Scope {
    require(scope.java.isInstance(value)) { "Scope factory for ${scope.qualifiedName} returned ${value.javaClass.name}." }
    @Suppress("UNCHECKED_CAST")
    return value as Scope
}
