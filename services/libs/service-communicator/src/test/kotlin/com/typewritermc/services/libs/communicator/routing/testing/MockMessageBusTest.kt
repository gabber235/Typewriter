package com.typewritermc.services.libs.communicator.routing.testing

import com.typewritermc.services.libs.communicator.interfaces.Message
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.seconds

class MockMessageBusTest : FunSpec({

    context("subscribe and simulateMessage") {
        test("delivers message to matching subscription") {
            runTest {
                val bus = MockMessageBus()
                val subscription = bus.subscribe("test.subject")

                var received: Message? = null
                val job = launch {
                    received = subscription.messages.first()
                }

                bus.simulateMessage("test.subject", "data".toByteArray(), "reply.to")

                job.join()

                received?.subject shouldBe "test.subject"
                received?.data?.let { String(it) } shouldBe "data"
                received?.replyTo shouldBe "reply.to"
            }
        }

        test("matches wildcard patterns") {
            runTest {
                val bus = MockMessageBus()
                val subscription = bus.subscribe("realm.*.player")

                var received: Message? = null
                val job = launch {
                    received = subscription.messages.first()
                }

                bus.simulateMessage("realm.abc123.player", "hello".toByteArray())

                job.join()

                received?.subject shouldBe "realm.abc123.player"
            }
        }

        test("does not deliver to non-matching subscription") {
            runTest {
                val bus = MockMessageBus()
                bus.subscribe("other.subject")

                bus.simulateMessage("test.subject", "data".toByteArray())

                bus.published.shouldBeEmpty()
            }
        }
    }

    context("publish") {
        test("tracks all published messages") {
            runTest {
                val bus = MockMessageBus()

                bus.publish("subject.a", "data1".toByteArray())
                bus.publish("subject.b", "data2".toByteArray())

                bus.published shouldHaveSize 2
                bus.published[0].subject shouldBe "subject.a"
                bus.published[1].subject shouldBe "subject.b"
            }
        }
    }

    context("request") {
        test("returns response from registered handler") {
            runTest {
                val bus = MockMessageBus()
                bus.onRequest("service.query") { requestData ->
                    "response to: ${String(requestData)}".toByteArray()
                }

                val response = bus.request("service.query", "hello".toByteArray(), 1.seconds)

                String(response.data!!) shouldBe "response to: hello"
            }
        }

        test("returns empty response when no handler registered") {
            runTest {
                val bus = MockMessageBus()

                val response = bus.request("unknown.service", "data".toByteArray(), 1.seconds)

                response.data shouldBe null
            }
        }
    }

    context("clear") {
        test("resets all state") {
            runTest {
                val bus = MockMessageBus()
                bus.publish("test", "data".toByteArray())
                bus.onRequest("service") { byteArrayOf() }

                bus.clear()

                bus.published.shouldBeEmpty()
            }
        }
    }
})
