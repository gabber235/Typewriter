package com.typewritermc.realm.authoring

import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

internal fun assertEquals(
    expected: Any?,
    actual: Any?,
) {
    actual shouldBe expected
}

internal fun assertTrue(actual: Boolean) {
    actual shouldBe true
}

internal fun assertFalse(actual: Boolean) {
    actual shouldBe false
}

internal inline fun <reified T : Any> assertIs(actual: Any?): T = actual.shouldBeInstanceOf<T>()

internal suspend inline fun <reified T : Throwable> assertFailsWith(noinline block: suspend () -> Unit): T {
    try {
        block()
    } catch (failure: Throwable) {
        if (failure is T) return failure
        throw failure
    }
    error("Expected ${T::class.simpleName} to be thrown.")
}
