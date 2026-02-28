package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.communicator.routing.testing.testRoute
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

class NatsRoutingTest : FunSpec({

    context("route registration") {
        test("registers routes with handle function") {
            var handled = false

            val result = testRoute(
                routing = {
                    route("cloud.in.realm.{realmId}") {
                        handle("player.join") {
                            handled = true
                        }
                    }
                },
                subject = "cloud.in.realm.test-realm.player.join",
                data = byteArrayOf()
            )

            result.success shouldBe true
            handled shouldBe true
        }

        test("extracts params and makes them available in handler") {
            var capturedRealmId: String? = null

            val result = testRoute(
                routing = {
                    route("cloud.in.realm.{realmId}") {
                        handle("action") {
                            capturedRealmId = params.require("realmId")
                        }
                    }
                },
                subject = "cloud.in.realm.my-realm-123.action",
                data = byteArrayOf()
            )

            result.success shouldBe true
            capturedRealmId shouldBe "my-realm-123"
        }

        test("nested routes work correctly") {
            var capturedRealmId: String? = null
            var capturedWorldId: String? = null

            val result = testRoute(
                routing = {
                    route("cloud.in.realm.{realmId}") {
                        route("world.{worldId}") {
                            handle("chunk.load") {
                                capturedRealmId = params.require("realmId")
                                capturedWorldId = params.require("worldId")
                            }
                        }
                    }
                },
                subject = "cloud.in.realm.r1.world.w2.chunk.load",
                data = byteArrayOf()
            )

            result.success shouldBe true
            capturedRealmId shouldBe "r1"
            capturedWorldId shouldBe "w2"
        }
    }

    context("reply and send") {
        test("reply adds to replies list") {
            val result = testRoute(
                routing = {
                    handle("test.action") {
                        reply("hello".toByteArray())
                    }
                },
                subject = "test.action",
                data = byteArrayOf()
            )

            result.replies.size shouldBe 1
            String(result.replies[0]) shouldBe "hello"
        }

        test("send adds to sent list") {
            val result = testRoute(
                routing = {
                    handle("test.action") {
                        send("other.subject", "notification".toByteArray())
                    }
                },
                subject = "test.action",
                data = byteArrayOf()
            )

            result.sent.size shouldBe 1
            result.sent[0].first shouldBe "other.subject"
            String(result.sent[0].second) shouldBe "notification"
        }

        test("handler can reply and send multiple messages") {
            val result = testRoute(
                routing = {
                    handle("test.action") {
                        reply("ack".toByteArray())
                        send("notify.a", "msg1".toByteArray())
                        send("notify.b", "msg2".toByteArray())
                    }
                },
                subject = "test.action",
                data = byteArrayOf()
            )

            result.replies.size shouldBe 1
            result.sent.size shouldBe 2
        }
    }

    context("handler delegation") {
        test("handler function delegates to NatsHandler") {
            var handlerInvoked = false
            val testHandler = object : NatsHandler {
                override suspend fun handle(ctx: NatsContext) {
                    handlerInvoked = true
                    ctx.reply("from handler".toByteArray())
                }
            }

            val result = testRoute(
                routing = {
                    route("test") {
                        handler("action") { testHandler }
                    }
                },
                subject = "test.action",
                data = byteArrayOf()
            )

            result.success shouldBe true
            handlerInvoked shouldBe true
            String(result.replies[0]) shouldBe "from handler"
        }
    }

    context("error handling") {
        test("captures errors thrown in handlers") {
            val result = testRoute(
                routing = {
                    handle("test.action") {
                        error("Something went wrong")
                    }
                },
                subject = "test.action",
                data = byteArrayOf()
            )

            result.success shouldBe false
            result.error?.message shouldContain "Something went wrong"
        }
    }

    context("message data access") {
        test("handler receives message data") {
            var receivedData: ByteArray? = null

            val result = testRoute(
                routing = {
                    handle("test.action") {
                        receivedData = message.data
                    }
                },
                subject = "test.action",
                data = "test payload".toByteArray()
            )

            result.success shouldBe true
            String(receivedData!!) shouldBe "test payload"
        }

        test("handler can access subject") {
            var receivedSubject: String? = null

            val result = testRoute(
                routing = {
                    handle("test.action") {
                        receivedSubject = message.subject
                    }
                },
                subject = "test.action",
                data = byteArrayOf()
            )

            result.success shouldBe true
            receivedSubject shouldBe "test.action"
        }
    }
})
