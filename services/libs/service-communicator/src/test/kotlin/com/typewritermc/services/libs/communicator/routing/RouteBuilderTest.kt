package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.communicator.routing.testing.MockMessageBus
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe

class RouteBuilderTest : FunSpec({

    context("route building") {
        test("handle creates route with joined subject") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)

            RouteBuilder(routing, "cloud.in.realm").apply {
                handle("action") { }
            }

            routing.routes shouldHaveSize 1
            routing.routes[0].pattern.subscriptionSubject shouldBe "cloud.in.realm.action"
        }

        test("nested routes accumulate prefix correctly") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)

            RouteBuilder(routing, "cloud.in").apply {
                route("realm.{realmId}") {
                    handle("action") { }
                }
            }

            routing.routes shouldHaveSize 1
            routing.routes[0].pattern.subscriptionSubject shouldBe "cloud.in.realm.*.action"
        }

        test("deeply nested routes work correctly") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)

            RouteBuilder(routing, "level1").apply {
                route("level2") {
                    route("level3") {
                        route("level4") {
                            handle("action") { }
                        }
                    }
                }
            }

            routing.routes shouldHaveSize 1
            routing.routes[0].pattern.subscriptionSubject shouldBe "level1.level2.level3.level4.action"
        }

        test("multiple handles in same route create separate routes") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)

            RouteBuilder(routing, "prefix").apply {
                handle("action1") { }
                handle("action2") { }
                handle("action3") { }
            }

            routing.routes shouldHaveSize 3
            routing.routes[0].pattern.subscriptionSubject shouldBe "prefix.action1"
            routing.routes[1].pattern.subscriptionSubject shouldBe "prefix.action2"
            routing.routes[2].pattern.subscriptionSubject shouldBe "prefix.action3"
        }

        test("handler function delegates to NatsHandler") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)
            var handlerCreated = false

            val testHandler = object : NatsHandler {
                override suspend fun handle(ctx: NatsContext) {
                    handlerCreated = true
                }
            }

            RouteBuilder(routing, "prefix").apply {
                handler("action") { testHandler }
            }

            routing.routes shouldHaveSize 1
        }
    }

    context("edge cases") {
        test("empty prefix joins correctly") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)

            RouteBuilder(routing, "").apply {
                handle("action") { }
            }

            routing.routes shouldHaveSize 1
            routing.routes[0].pattern.subscriptionSubject shouldBe "action"
        }

        test("empty action joins correctly") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)

            RouteBuilder(routing, "prefix").apply {
                handle("") { }
            }

            routing.routes shouldHaveSize 1
            routing.routes[0].pattern.subscriptionSubject shouldBe "prefix"
        }

        test("params in nested routes are preserved") {
            val mockBus = MockMessageBus()
            val routing = NatsRouting(mockBus)

            RouteBuilder(routing, "cloud.in.realm.{realmId}").apply {
                route("world.{worldId}") {
                    handle("chunk.{chunkId}") { }
                }
            }

            routing.routes shouldHaveSize 1
            routing.routes[0].pattern.subscriptionSubject shouldBe "cloud.in.realm.*.world.*.chunk.*"
        }
    }
})
