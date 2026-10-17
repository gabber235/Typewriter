package com.typewritermc.realm.repository

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
