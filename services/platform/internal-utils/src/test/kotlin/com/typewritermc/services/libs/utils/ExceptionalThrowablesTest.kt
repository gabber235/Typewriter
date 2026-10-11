package com.typewritermc.services.libs.utils

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.types.shouldBeSameInstanceAs
import kotlinx.coroutines.CancellationException

val ExceptionalThrowablesTest by testSuite {
    test("finds every exceptional throwable kind directly") {
        listOf(
            CancellationException("cancelled"),
            TestVirtualMachineError(),
            threadDeath(),
            LinkageError("linkage"),
        ).forEach { it.findExceptional() shouldBeSameInstanceAs it }
    }

    test("finds exceptional throwables through causes and suppressed throwables") {
        val cause = CancellationException("cause")
        IllegalStateException("wrapper", cause).findExceptional() shouldBeSameInstanceAs cause

        val suppressed = LinkageError("suppressed")
        val wrapper = IllegalStateException("wrapper").apply { addSuppressed(suppressed) }
        wrapper.findExceptional() shouldBeSameInstanceAs suppressed
    }

    test("traverses cycles safely and returns null for ordinary throwables") {
        val first = IllegalStateException("first")
        val second = IllegalStateException("second", first)
        first.initCause(second)
        first.findExceptional().shouldBeNull()
    }

    test("searches causes before suppressed throwables deterministically") {
        val cause = CancellationException("cause")
        val suppressed = LinkageError("suppressed")
        val wrapper = IllegalStateException("wrapper", cause).apply { addSuppressed(suppressed) }
        wrapper.findExceptional() shouldBeSameInstanceAs cause
    }

    test("rethrows the exact exceptional throwable instance") {
        val exceptional = threadDeath()
        val wrapper = IllegalStateException("wrapper").apply { addSuppressed(exceptional) }
        shouldThrow<Throwable> { wrapper.rethrowExceptional() } shouldBeSameInstanceAs exceptional
    }
}

@Suppress("DEPRECATION")
private fun threadDeath(): Throwable = ThreadDeath()

private class TestVirtualMachineError : VirtualMachineError("fatal")
