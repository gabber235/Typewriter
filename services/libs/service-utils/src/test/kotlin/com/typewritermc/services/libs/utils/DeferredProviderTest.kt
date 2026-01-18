package com.typewritermc.services.libs.utils

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.milliseconds

class DeferredProviderTest : FunSpec({

    context("Initial State") {

        test("isSet returns false before value is set") {
            val provider = DeferredProvider<String>()
            provider.isSet shouldBe false
        }

        test("getOrNull returns null before value is set") {
            val provider = DeferredProvider<String>()
            provider.getOrNull() shouldBe null
        }
    }

    context("Setting Values") {

        test("set completes the deferred and isSet becomes true") {
            val provider = DeferredProvider<String>()
            provider.set("hello")
            provider.isSet shouldBe true
        }

        test("set throws when value already set") {
            val provider = DeferredProvider<String>()
            provider.set("first")

            shouldThrow<IllegalStateException> {
                provider.set("second")
            }
        }

        test("trySet returns true on first call") {
            val provider = DeferredProvider<String>()
            provider.trySet("value") shouldBe true
        }

        test("trySet returns false when already set") {
            val provider = DeferredProvider<String>()
            provider.trySet("first") shouldBe true
            provider.trySet("second") shouldBe false
        }

        test("trySet does not throw when already set") {
            val provider = DeferredProvider<String>()
            provider.set("first")
            provider.trySet("second") shouldBe false
        }
    }

    context("Getting Values") {

        test("get returns value after set") {
            val provider = DeferredProvider<String>()
            provider.set("expected")
            provider.get() shouldBe "expected"
        }

        test("getOrNull returns value after set") {
            val provider = DeferredProvider<String>()
            provider.set("expected")
            provider.getOrNull() shouldBe "expected"
        }

        test("get suspends until value is set") {
            val provider = DeferredProvider<String>()

            val deferred = async {
                provider.get()
            }

            delay(50.milliseconds)
            provider.set("delayed-value")

            deferred.await() shouldBe "delayed-value"
        }

        test("multiple get calls return same value") {
            val provider = DeferredProvider<String>()
            provider.set("consistent")

            provider.get() shouldBe "consistent"
            provider.get() shouldBe "consistent"
            provider.getOrNull() shouldBe "consistent"
        }

        test("get with timeout succeeds when value set before timeout") {
            val provider = DeferredProvider<String>()

            launch {
                delay(50.milliseconds)
                provider.set("in-time")
            }

            provider.get(200.milliseconds) shouldBe "in-time"
        }

        test("get with timeout throws when value not set before timeout") {
            val provider = DeferredProvider<Int>()

            shouldThrow<TimeoutCancellationException> {
                provider.get(50.milliseconds)
            }
        }
    }

    context("Type Safety") {

        test("works with nullable types") {
            val provider = DeferredProvider<String?>()
            provider.set(null)
            provider.get() shouldBe null
            provider.isSet shouldBe true
        }

        test("works with complex types") {
            data class ComplexType(val id: Int, val name: String)

            val provider = DeferredProvider<ComplexType>()
            val value = ComplexType(42, "test")
            provider.set(value)

            provider.get() shouldBe value
        }
    }

    context("Concurrent Access") {

        test("multiple coroutines waiting on get all receive the value") {
            val provider = DeferredProvider<String>()

            val results = (1..5).map {
                async { provider.get() }
            }

            delay(50.milliseconds)
            provider.set("shared")

            results.forEach { deferred ->
                deferred.await() shouldBe "shared"
            }
        }
    }
})
