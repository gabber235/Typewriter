package com.typewritermc.services.libs.utils

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.advanceTimeBy
import kotlin.time.Duration.Companion.milliseconds

@OptIn(ExperimentalCoroutinesApi::class)
val StateProviderTest by testSuite {
    testSuite("Happy Path Scenarios") {
        test("get() returns initial value when no updates have occurred") {
            val provider = StateProvider("initial")

            provider.get() shouldBe "initial"
        }

        test("set() updates the current value") {
            val provider = StateProvider("initial")

            provider.set("updated")

            provider.get() shouldBe "updated"
        }

        test("get() returns the most recent value after multiple updates") {
            val provider = StateProvider(0)

            provider.set(1)
            provider.set(2)
            provider.set(3)

            provider.get() shouldBe 3
        }

        test("awaitValue() returns immediately when predicate already satisfied") {
            val provider = StateProvider(10)

            val result = provider.awaitValue { it > 5 }

            result shouldBe 10
        }

        test("awaitValue() suspends until predicate becomes satisfied") {
            val provider = StateProvider(0)

            val deferred =
                async {
                    provider.awaitValue { it >= 5 }
                }

            testScope.advanceTimeBy(10.milliseconds)
            provider.set(3)
            testScope.advanceTimeBy(10.milliseconds)
            provider.set(5)

            deferred.await() shouldBe 5
        }
    }

    testSuite("Edge Cases") {
        test("awaitValue() with already-satisfied predicate returns initial value") {
            val provider = StateProvider("match")

            val result = provider.awaitValue { it.startsWith("m") }

            result shouldBe "match"
        }

        test("concurrent set() calls result in last value being visible") {
            val provider = StateProvider(0)

            val job1 =
                launch {
                    repeat(100) { provider.set(it) }
                }
            val job2 =
                launch {
                    repeat(100) { provider.set(it + 1000) }
                }

            job1.join()
            job2.join()

            val finalValue = provider.get()
            (finalValue == 99 || finalValue == 1099) shouldBe true
        }

        test("multiple collectors receive updates from state flow") {
            val provider = StateProvider(0)

            val collected1 = mutableListOf<Int>()
            val collected2 = mutableListOf<Int>()

            val job1 =
                launch {
                    provider.state.take(3).toList(collected1)
                }
            val job2 =
                launch {
                    provider.state.take(3).toList(collected2)
                }

            testScope.advanceTimeBy(10.milliseconds)
            provider.set(1)
            testScope.advanceTimeBy(10.milliseconds)
            provider.set(2)

            job1.join()
            job2.join()

            collected1 shouldBe listOf(0, 1, 2)
            collected2 shouldBe listOf(0, 1, 2)
        }
    }

    testSuite("Nullable Extension Methods") {
        test("awaitNonNull() returns immediately when value is already set") {
            val provider = StateProvider<String?>("value")

            val result = provider.awaitNonNull()

            result shouldBe "value"
        }

        test("awaitNonNull() suspends until value becomes non-null") {
            val provider = StateProvider<String?>(null)

            val deferred =
                async {
                    provider.awaitNonNull()
                }

            testScope.advanceTimeBy(10.milliseconds)
            provider.set("now set")

            deferred.await() shouldBe "now set"
        }

        test("awaitNonNull() returns new value after update from null") {
            val provider = StateProvider<String?>(null)

            val deferred =
                async {
                    provider.awaitNonNull()
                }

            testScope.advanceTimeBy(10.milliseconds)
            provider.set("first")
            testScope.advanceTimeBy(10.milliseconds)
            provider.set("second")

            deferred.await() shouldBe "first"
        }

        test("require() throws when value is null") {
            val provider = StateProvider<String?>(null)

            shouldThrow<IllegalStateException> {
                provider.require()
            }
        }

        test("require() returns value when set") {
            val provider = StateProvider<String?>("value")

            provider.require() shouldBe "value"
        }

        test("awaitNonNull() works after value is set to null then back to non-null") {
            val provider = StateProvider<String?>("initial")

            provider.set(null)

            val deferred =
                async {
                    provider.awaitNonNull()
                }

            testScope.advanceTimeBy(10.milliseconds)
            provider.set("restored")

            deferred.await() shouldBe "restored"
        }
    }
}
