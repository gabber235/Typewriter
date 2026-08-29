package com.typewritermc.services.libs.utils

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.nanoseconds
import kotlin.time.Duration.Companion.seconds

val RetryPolicyTest by testSuite {
    testSuite("validation") {
        test("fixed requires a finite positive duration") {
            listOf(Duration.ZERO, (-1).nanoseconds, Duration.INFINITE).forEach {
                shouldThrow<IllegalArgumentException> { RetryPolicy.fixed(it) }
            }
        }

        test("exponential requires finite positive ordered durations") {
            listOf(Duration.ZERO, (-1).seconds, Duration.INFINITE).forEach {
                shouldThrow<IllegalArgumentException> { RetryPolicy.exponential(it, 10.seconds) }
                shouldThrow<IllegalArgumentException> { RetryPolicy.exponential(1.seconds, it) }
            }
            shouldThrow<IllegalArgumentException> { RetryPolicy.exponential(2.seconds, 1.seconds) }
        }

        test("exponential requires a finite multiplier greater than one") {
            listOf(Double.NEGATIVE_INFINITY, 1.0, 0.0, Double.POSITIVE_INFINITY, Double.NaN).forEach {
                shouldThrow<IllegalArgumentException> {
                    RetryPolicy.exponential(1.seconds, 10.seconds, multiplier = it)
                }
            }
        }

        test("exponential requires a normalized jitter ratio") {
            listOf(-0.01, 1.01, Double.NEGATIVE_INFINITY, Double.POSITIVE_INFINITY, Double.NaN).forEach {
                shouldThrow<IllegalArgumentException> {
                    RetryPolicy.exponential(1.seconds, 10.seconds, jitterRatio = it)
                }
            }
        }

        test("delay calculation validates attempt and sample for every policy") {
            listOf(RetryPolicy.fixed(1.seconds), RetryPolicy.exponential(1.seconds, 10.seconds)).forEach { policy ->
                shouldThrow<IllegalArgumentException> { policy.delayFor(-1) }
                listOf(-0.01, 1.01, Double.NaN).forEach { sample ->
                    shouldThrow<IllegalArgumentException> { policy.delayFor(0, sample) }
                }
            }
        }
    }

    testSuite("calculation") {
        test("fixed returns the same delay for every attempt and sample") {
            val policy = RetryPolicy.fixed(125.milliseconds)

            policy.delayFor(0, 0.0) shouldBe 125.milliseconds
            policy.delayFor(Long.MAX_VALUE, 0.5) shouldBe 125.milliseconds
            policy.delayFor(42, 1.0) shouldBe 125.milliseconds
        }

        test("exponential grows from zero-based attempts") {
            val policy = RetryPolicy.exponential(100.milliseconds, 10.seconds, multiplier = 3.0)

            policy.delayFor(0) shouldBe 100.milliseconds
            policy.delayFor(1) shouldBe 300.milliseconds
            policy.delayFor(2) shouldBe 900.milliseconds
        }

        test("growth saturates at maximum without overflowing") {
            val policy = RetryPolicy.exponential(1.nanoseconds, 7.seconds, multiplier = Double.MAX_VALUE)

            policy.delayFor(1) shouldBe 7.seconds
            policy.delayFor(Long.MAX_VALUE) shouldBe 7.seconds
        }

        test("jitter edges and midpoint produce bounded ratios") {
            val policy =
                RetryPolicy.exponential(
                    initial = 10.seconds,
                    maximum = 1_000.seconds,
                    jitterRatio = 0.2,
                )

            policy.delayFor(0, 0.0) shouldBe 8.seconds
            policy.delayFor(0, 0.5) shouldBe 10.seconds
            policy.delayFor(0, 1.0) shouldBe 12.seconds
        }

        test("jitter remains positive and maximum bounded at extremes") {
            val policy =
                RetryPolicy.exponential(
                    initial = 10.nanoseconds,
                    maximum = 100.nanoseconds,
                    jitterRatio = 1.0,
                )

            policy.delayFor(0, 0.0) shouldBe 1.nanoseconds
            policy.delayFor(Long.MAX_VALUE, 1.0) shouldBe 100.nanoseconds
        }

        test("equal inputs always produce equal outputs") {
            val policy = RetryPolicy.exponential(3.seconds, 30.seconds, jitterRatio = 0.35)

            val results = List(100) { policy.delayFor(4, 0.731) }
            results.toSet().size shouldBe 1
        }
    }
}
