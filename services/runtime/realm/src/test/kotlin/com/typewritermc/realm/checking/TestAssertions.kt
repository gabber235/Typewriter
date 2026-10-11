package com.typewritermc.realm.checking

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.types.shouldBeInstanceOf

internal fun assertEquals(
    expected: Any?,
    actual: Any?,
) {
    actual shouldBe expected
}

internal fun assertNotEquals(
    unexpected: Any?,
    actual: Any?,
) {
    actual shouldNotBe unexpected
}

internal fun assertTrue(actual: Boolean) {
    actual shouldBe true
}

internal fun assertFalse(actual: Boolean) {
    actual shouldBe false
}

internal inline fun <reified T : Any> assertIs(actual: Any?): T = actual.shouldBeInstanceOf<T>()

internal inline fun <reified T : Throwable> assertFailsWith(noinline block: () -> Unit): T = shouldThrow<T>(block)
