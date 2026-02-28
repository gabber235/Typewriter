package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.communicator.routing.testing.MockMessageBus
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest

@OptIn(ExperimentalCoroutinesApi::class)
class NatsDispatcherTest : FunSpec({

    context("lifecycle management") {
        test("start subscribes to all registered routes") {
            runTest {
                val mockBus = MockMessageBus()
                val routing = natsRouting(mockBus) {
                    handle("route.a") { }
                    handle("route.b") { }
                    handle("route.c") { }
                }
                val dispatcher = NatsDispatcher(routing, this)

                dispatcher.start()
                advanceUntilIdle()

                dispatcher.stop()
            }
        }

        test("handler receives messages after start") {
            runTest {
                val mockBus = MockMessageBus()
                var received = false

                val routing = natsRouting(mockBus) {
                    handle("test.action") {
                        received = true
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("test.action", byteArrayOf())
                advanceUntilIdle()

                received shouldBe true
                dispatcher.stop()
            }
        }
    }

    context("error isolation") {
        test("handler exception does not crash dispatcher") {
            runTest {
                val mockBus = MockMessageBus()
                var secondHandlerCalled = false

                val routing = natsRouting(mockBus) {
                    handle("error.action") {
                        error("Intentional error")
                    }
                    handle("ok.action") {
                        secondHandlerCalled = true
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("error.action", byteArrayOf())
                advanceUntilIdle()

                mockBus.simulateMessage("ok.action", byteArrayOf())
                advanceUntilIdle()

                secondHandlerCalled shouldBe true
                dispatcher.stop()
            }
        }

        test("subsequent messages processed after handler exception") {
            runTest {
                val mockBus = MockMessageBus()
                var callCount = 0

                val routing = natsRouting(mockBus) {
                    handle("count.action") {
                        callCount++
                        if (callCount == 1) {
                            error("First call fails")
                        }
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("count.action", byteArrayOf())
                advanceUntilIdle()
                mockBus.simulateMessage("count.action", byteArrayOf())
                advanceUntilIdle()
                mockBus.simulateMessage("count.action", byteArrayOf())
                advanceUntilIdle()

                callCount shouldBe 3
                dispatcher.stop()
            }
        }
    }

    context("param extraction") {
        test("params extracted from actual subject") {
            runTest {
                val mockBus = MockMessageBus()
                var extractedRealmId: String? = null

                val routing = natsRouting(mockBus) {
                    handle("realm.{realmId}.action") {
                        extractedRealmId = params.require("realmId")
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("realm.my-realm-123.action", byteArrayOf())
                advanceUntilIdle()

                extractedRealmId shouldBe "my-realm-123"
                dispatcher.stop()
            }
        }

        test("multiple params extracted correctly") {
            runTest {
                val mockBus = MockMessageBus()
                var extractedRealmId: String? = null
                var extractedPlayerId: String? = null

                val routing = natsRouting(mockBus) {
                    handle("realm.{realmId}.player.{playerId}") {
                        extractedRealmId = params.require("realmId")
                        extractedPlayerId = params.require("playerId")
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("realm.r1.player.p1", byteArrayOf())
                advanceUntilIdle()

                extractedRealmId shouldBe "r1"
                extractedPlayerId shouldBe "p1"
                dispatcher.stop()
            }
        }
    }

    context("message handling") {
        test("handler receives message data") {
            runTest {
                val mockBus = MockMessageBus()
                var receivedData: ByteArray? = null

                val routing = natsRouting(mockBus) {
                    handle("test.action") {
                        receivedData = message.data
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("test.action", "hello".toByteArray())
                advanceUntilIdle()

                String(receivedData!!) shouldBe "hello"
                dispatcher.stop()
            }
        }

        test("handler can reply to message") {
            runTest {
                val mockBus = MockMessageBus()

                val routing = natsRouting(mockBus) {
                    handle("test.action") {
                        reply("response".toByteArray())
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("test.action", byteArrayOf(), replyTo = "inbox.123")
                advanceUntilIdle()

                mockBus.published.size shouldBe 1
                mockBus.published[0].subject shouldBe "inbox.123"
                dispatcher.stop()
            }
        }

        test("handler can send to other subjects") {
            runTest {
                val mockBus = MockMessageBus()

                val routing = natsRouting(mockBus) {
                    handle("test.action") {
                        send("notify.a", "msg1".toByteArray())
                        send("notify.b", "msg2".toByteArray())
                    }
                }
                val dispatcher = NatsDispatcher(routing, this)
                dispatcher.start()
                advanceUntilIdle()

                mockBus.simulateMessage("test.action", byteArrayOf())
                advanceUntilIdle()

                mockBus.published.size shouldBe 2
                mockBus.published[0].subject shouldBe "notify.a"
                mockBus.published[1].subject shouldBe "notify.b"
                dispatcher.stop()
            }
        }
    }
})
