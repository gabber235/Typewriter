package com.typewritermc.engine.runtime

import com.typewritermc.engine.events.ChainPickup
import com.typewritermc.engine.events.ImmediateChainPickup
import com.typewritermc.engine.events.NoSubjectWork
import com.typewritermc.engine.events.SubjectWork
import com.typewritermc.engine.events.testing.CountingWork
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.events.testing.provided
import com.typewritermc.engine.events.testing.reason
import com.typewritermc.engine.events.testing.testShapes
import com.typewritermc.engine.events.testing.verdict
import com.typewritermc.engine.runtime.testing.PublicationRecorder
import com.typewritermc.engine.runtime.testing.WiredEngine
import com.typewritermc.engine.runtime.testing.messagesOf
import com.typewritermc.engine.runtime.testing.testEngineKind
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.readSessionEntry
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.EventShape
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.HasChat
import com.typewritermc.events.Outcome
import com.typewritermc.events.ProtagonistLeft
import com.typewritermc.events.ProtagonistLeftEventShape
import com.typewritermc.events.Source
import com.typewritermc.events.VerdictHandler
import com.typewritermc.events.deny
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.onBroker
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import org.koin.dsl.module
import skirout.editor.v1.type_catalog.PublicationId
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.time.Duration.Companion.seconds

/** The Koin of one engine deployment: engine-core's session keeping, wired with the parts its engine kind brings. */
val EngineWiringTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("an engine deployment reports its sessions as the engine the loader assigned it") {
        NatsTestServer.startWithJetStream().use { server ->
            onBroker(server.url) {
                val buckets = buckets()
                check(buckets.ensure(SessionsBucket.declaration("realm")) is KeyValueOpen.Opened)
                WiredEngine(testEngineKind, buckets = buckets).use { engine ->
                    val uuid = UUID.randomUUID().toString()
                    val protagonist = Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid))

                    engine.reporter.connected(protagonist, SessionId(uuid))

                    val observer = (buckets.open(SessionsBucket.name("realm")) as KeyValueOpen.Opened).bucket
                    eventually(10.seconds) {
                        observer.readSessionEntry(protagonist, SessionId(uuid)).shouldNotBeNull().holder shouldBe EngineId("engine")
                    }
                }
            }
        }
    }

    test("an engine kind that brings no session timings fails at start naming them") {
        val failure = shouldThrow<Exception> { WiredEngine(module { single<ChainPickup> { ImmediateChainPickup(get()) } }) }

        messagesOf(failure) shouldContain "SessionTimings"
    }

    test("an engine kind that brings no chain pickup fails at start naming it, since its chains would never run") {
        val failure = shouldThrow<Exception> { WiredEngine(module { single<SessionTimings> { SessionHarness.SHORT } }) }

        messagesOf(failure) shouldContain "ChainPickup"
    }

    test("an engine with two subject works fails at start naming both, since only one may count chain work") {
        val failure =
            shouldThrow<Exception> {
                WiredEngine(
                    testEngineKind,
                    listOf(provided(CountingWork(), listOf(SubjectWork::class)), provided(NoSubjectWork, listOf(SubjectWork::class))),
                )
            }

        messagesOf(failure) shouldContain "SubjectWork"
        messagesOf(failure) shouldContain "CountingWork"
        messagesOf(failure) shouldContain "NoSubjectWork"
    }

    test("an engine part's handler runs for its source's occurrences once the engine starts") {
        val pokes = TestSource(Poke::class)
        val guard = verdict(Poke::class) { _, _ -> deny(reason("guarded")) }
        WiredEngine(
            testEngineKind,
            listOf(provided(pokes, listOf(Source::class)), provided(guard, listOf(VerdictHandler::class, HandlerPlan::class))),
        ).use {
            pokes.fire(Poke()) shouldBe Outcome.Denied(Poke(), reason("guarded"))
        }
    }

    test("an event about a protagonist this engine holds no session of runs no handler, even while NATS is down") {
        val pokes = TestSource(Poke::class)
        val poked = CopyOnWriteArrayList<Poke>()
        WiredEngine(
            testEngineKind,
            listOf(
                provided(pokes, listOf(Source::class)),
                provided(testShapes.single { it.event == Poke::class }, listOf(EventShape::class)),
                provided(after(Poke::class) { poke, _ -> poked += poke }, listOf(AfterHandler::class, HandlerPlan::class)),
            ),
        ).use { engine ->
            val here = protagonist("here")
            val elsewhere = protagonist("elsewhere")
            engine.reporter.connected(here, SessionId("here"))

            pokes.fire(Poke(elsewhere)) shouldBe null
            pokes.fire(Poke(here)) shouldBe Outcome.Allowed(Poke(here))
            eventually(5.seconds) { poked.map { it.protagonist } shouldContain here }
            poked.map { it.protagonist } shouldNotContain elsewhere
        }
    }

    test("a protagonist whose last session expired still reaches its handler on the engine that held it") {
        SessionHarness.start().use { harness ->
            harness.createBucket()
            val left = CopyOnWriteArrayList<ProtagonistLeft>()
            WiredEngine(
                testEngineKind,
                listOf(
                    provided(ProtagonistLeftEventShape(), listOf(EventShape::class)),
                    provided(after(ProtagonistLeft::class) { event, _ -> left += event }, listOf(AfterHandler::class, HandlerPlan::class)),
                ),
                harness.messaging().buckets,
            ).use { engine ->
                val (protagonist, id) = harness.player()
                engine.reporter.connected(protagonist, id)
                harness.eventually { harness.entry(protagonist, id)?.holder == EngineId("engine") }

                engine.reporter.disconnected(id)

                harness.eventually { ProtagonistLeft(protagonist) in left }
            }
        }
    }

    test("an engine part that needs what the engine does not provide fails at start naming both") {
        val needy = TestSource(Poke::class)
        val failure =
            shouldThrow<Exception> {
                WiredEngine(testEngineKind, listOf(provided(needy, listOf(Source::class), needs = HasChat::class)))
            }

        messagesOf(failure) shouldContain "TestSource needs HasChat"
    }

    test("an engine part that observes publications hears each publication the engine applied, in order") {
        val observer = PublicationRecorder()
        WiredEngine(testEngineKind, listOf(provided(observer, listOf(PublicationObserver::class)))).use { engine ->
            engine.applied(PublicationId(value = "first"))
            engine.applied(PublicationId(value = "second"))

            observer.applied shouldBe listOf(PublicationId(value = "first"), PublicationId(value = "second"))
        }
    }
}
