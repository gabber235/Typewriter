package com.typewritermc.services.libs.utils

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.types.shouldBeSameInstanceAs

val CleanupFailuresTest by testSuite {
    test("runs every step and throws the first failure with later failures suppressed") {
        val first = IllegalStateException("first")
        val second = IllegalArgumentException("second")
        val completed = mutableListOf<String>()

        val thrown =
            shouldThrow<IllegalStateException> {
                closeAll {
                    attempt { throw first }
                    attempt { completed += "middle" }
                    attempt { throw second }
                }
            }

        thrown shouldBeSameInstanceAs first
        thrown.suppressed.toList() shouldContainExactly listOf(second)
        completed shouldContainExactly listOf("middle")
    }

    test("suppresses cleanup failures into a primary failure without throwing") {
        val primary = IllegalStateException("primary")
        val cleanup = IllegalArgumentException("cleanup")

        listOf(AutoCloseable { throw cleanup }, null, AutoCloseable { throw primary }).closeAll(primary)

        primary.suppressed.toList() shouldContainExactly listOf(cleanup)
    }

    test("closes resources in iteration order and completes without failures") {
        val closed = mutableListOf<Int>()

        listOf(AutoCloseable { closed += 1 }, AutoCloseable { closed += 2 }).closeAll()

        closed shouldContainExactly listOf(1, 2)
    }
}
