package com.typewritermc.discovery

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

val RuntimeCleanupOwnerTest by testSuite {
    test("releases resources once in reverse order and rejects late ownership") {
        runTest {
            val events = mutableListOf<String>()
            val ownership = RuntimeCleanupOwner()
            val resource = AutoCloseable { events += "resource" }
            ownership.own(resource) shouldBe resource
            ownership.own { events += "flush" }

            ownership.close()
            ownership.close()

            events shouldContainExactly listOf("flush", "resource")
            shouldThrow<IllegalStateException> { ownership.own { events += "late" } }
            shouldThrow<IllegalStateException> { ownership.own(resource) }
        }
    }

    test("attempts every cleanup and retains later causes on the first failure") {
        runTest {
            val events = mutableListOf<String>()
            val ownership = RuntimeCleanupOwner()
            val first = IllegalStateException("first")
            val later = IllegalArgumentException("later")
            ownership.own { events += "last" }
            ownership.own {
                events += "later"
                throw later
            }
            ownership.own {
                events += "first"
                throw first
            }

            shouldThrow<IllegalStateException> { ownership.close() } shouldBe first
            first.suppressed.toList() shouldContainExactly listOf(later)
            events shouldContainExactly listOf("first", "later", "last")
            ownership.close()
            events shouldContainExactly listOf("first", "later", "last")
        }
    }

    test("repeated throwable instances do not interrupt the remaining cleanup") {
        runTest {
            val ownership = RuntimeCleanupOwner()
            val failure = IllegalStateException("shared")
            var released = false
            ownership.own { released = true }
            ownership.own { throw failure }
            ownership.own { throw failure }

            shouldThrow<IllegalStateException> { ownership.close() } shouldBe failure
            released shouldBe true
        }
    }
}
