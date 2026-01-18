package com.typewritermc.services.libs.utils

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch

class StateProviderTest : FunSpec({

    context("Happy Path Scenarios") {

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

            val deferred = async {
                provider.awaitValue { it >= 5 }
            }

            delay(10)
            provider.set(3)
            delay(10)
            provider.set(5)

            deferred.await() shouldBe 5
        }
    }

    context("Edge Cases") {

        test("awaitValue() with already-satisfied predicate returns initial value") {
            val provider = StateProvider("match")

            val result = provider.awaitValue { it.startsWith("m") }

            result shouldBe "match"
        }

        test("concurrent set() calls result in last value being visible") {
            val provider = StateProvider(0)

            val job1 = launch {
                repeat(100) { provider.set(it) }
            }
            val job2 = launch {
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

            val job1 = launch {
                provider.state.take(3).toList(collected1)
            }
            val job2 = launch {
                provider.state.take(3).toList(collected2)
            }

            delay(10)
            provider.set(1)
            delay(10)
            provider.set(2)

            job1.join()
            job2.join()

            collected1 shouldBe listOf(0, 1, 2)
            collected2 shouldBe listOf(0, 1, 2)
        }
    }
})
