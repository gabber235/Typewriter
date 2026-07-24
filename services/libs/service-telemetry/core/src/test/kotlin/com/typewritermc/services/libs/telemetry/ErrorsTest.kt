package com.typewritermc.services.libs.telemetry

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeSameInstanceAs
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.test.runTest

val ErrorsTest by testSuite {
    test("slug validates lowercase kebab case") {
        ErrorSlug.of("repository-load-failed")
        listOf("", "Bad", "bad_slug", "bad--slug", "-bad", "bad-", "bad slug", "bad.slug").forEach {
            shouldThrow<IllegalArgumentException> { ErrorSlug.of(it) }
        }
    }

    test("wrapping is non nesting and preserves cause") {
        val cause = IllegalStateException("broken")
        val inner = SluggedException.wrap(ErrorSlug.of("inner-failed"), cause)
        SluggedException.wrap(ErrorSlug.of("outer-failed"), inner) shouldBeSameInstanceAs inner
        inner.cause shouldBeSameInstanceAs cause
    }

    test("sync helper wraps once at the innermost source") {
        val cause = IllegalArgumentException("broken")
        val thrown = shouldThrow<SluggedException> {
            withErrorSlug(ErrorSlug.of("outer-failed")) {
                withErrorSlug(ErrorSlug.of("inner-failed")) { throw cause }
            }
        }
        thrown.slug.value shouldBe "inner-failed"
        thrown.cause shouldBeSameInstanceAs cause
    }

    test("suspend helper wraps once and leaves cancellation unwrapped") {
        runTest {
            val cause = IllegalArgumentException("broken")
            val thrown = shouldThrow<SluggedException> {
                withErrorSlugSuspending(ErrorSlug.of("suspend-failed")) { throw cause }
            }
            thrown.cause shouldBeSameInstanceAs cause

            val cancellation = CancellationException("cancel")
            shouldThrow<CancellationException> {
                withErrorSlugSuspending(ErrorSlug.of("must-not-wrap")) { throw cancellation }
            } shouldBeSameInstanceAs cancellation
        }
    }

    test("Result helper preserves success and existing classifications") {
        Result.success(7).withErrorSlug(ErrorSlug.of("unused-failed")).getOrThrow() shouldBe 7

        val cause = IllegalStateException("broken")
        val classified = Result.failure<Int>(cause).withErrorSlug(ErrorSlug.of("result-failed")).exceptionOrNull()
        (classified is SluggedException) shouldBe true
        classified?.cause shouldBeSameInstanceAs cause

        val existing = SluggedException.wrap(ErrorSlug.of("existing-failed"), cause)
        Result.failure<Int>(existing).withErrorSlug(ErrorSlug.of("outer-failed")).exceptionOrNull() shouldBeSameInstanceAs existing
    }

    test("Result helper rethrows cancellation instead of classifying it") {
        val cancellation = CancellationException("cancel")
        shouldThrow<CancellationException> {
            Result.failure<Int>(cancellation).withErrorSlug(ErrorSlug.of("must-not-wrap"))
        } shouldBeSameInstanceAs cancellation
    }
}
