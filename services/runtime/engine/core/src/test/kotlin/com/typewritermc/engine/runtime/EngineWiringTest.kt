package com.typewritermc.engine.runtime

import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.provided
import com.typewritermc.engine.events.testing.reason
import com.typewritermc.engine.events.testing.verdict
import com.typewritermc.engine.runtime.testing.OTHER
import com.typewritermc.engine.runtime.testing.PAGE
import com.typewritermc.engine.runtime.testing.PublicationRecorder
import com.typewritermc.engine.runtime.testing.assemble
import com.typewritermc.engine.runtime.testing.facts
import com.typewritermc.engine.runtime.testing.resource
import com.typewritermc.engine.runtime.testing.wiredDeploymentContext
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.readSessionEntry
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.HasChat
import com.typewritermc.events.Outcome
import com.typewritermc.events.Source
import com.typewritermc.events.VerdictHandler
import com.typewritermc.events.deny
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.identity.SessionReporter
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.onBroker
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.dsl.module
import skirout.editor.v1.type_catalog.PublicationId
import java.util.UUID
import kotlin.time.Duration.Companion.seconds

/** The Koin of one engine deployment: engine-core's session keeping, wired with the parts its engine kind brings. */
val EngineWiringTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("an engine deployment reports its sessions as the engine the loader assigned it") {
        NatsTestServer.startWithJetStream().use { server ->
            onBroker(server.url) {
                val buckets = buckets()
                check(buckets.ensure(SessionsBucket.declaration("realm")) is KeyValueOpen.Opened)
                val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
                val wiring =
                    EngineWiring(wiredDeploymentContext(buckets), scope, module { single<SessionTimings> { SessionHarness.SHORT } })
                try {
                    val uuid = UUID.randomUUID().toString()
                    val protagonist = Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid))

                    wiring.application.koin
                        .get<SessionReporter>()
                        .connected(protagonist, SessionId(uuid))

                    val observer = (buckets.open(SessionsBucket.name("realm")) as KeyValueOpen.Opened).bucket
                    eventually(10.seconds) {
                        observer.readSessionEntry(protagonist, SessionId(uuid)).shouldNotBeNull().holder shouldBe EngineId("engine")
                    }
                } finally {
                    wiring.close()
                    scope.cancel()
                }
            }
        }
    }

    test("an engine kind that brings no session timings fails at start naming them") {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        try {
            val failure = shouldThrow<Exception> { EngineWiring(wiredDeploymentContext(), scope, module { }) }

            generateSequence<Throwable>(failure) { it.cause }.joinToString(" | ") { it.message.orEmpty() } shouldContain "SessionTimings"
        } finally {
            scope.cancel()
        }
    }

    test("an engine part's handler runs for its source's occurrences once the engine starts") {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val pokes = TestSource(Poke::class)
        val guard = verdict(Poke::class) { _, _ -> deny(reason("guarded")) }
        val wiring =
            EngineWiring(
                wiredDeploymentContext(),
                scope,
                module { single<SessionTimings> { SessionHarness.SHORT } },
                listOf(provided(pokes, listOf(Source::class)), provided(guard, listOf(VerdictHandler::class, HandlerPlan::class))),
            )
        try {
            wiring.events.publish(PublishedEntries.EMPTY)

            pokes.fire(Poke()) shouldBe Outcome.Denied(Poke(), reason("guarded"))
        } finally {
            wiring.close()
            scope.cancel()
        }
    }

    test("an engine part that needs what the engine does not provide fails at start naming both") {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        try {
            val needy = TestSource(Poke::class)
            val failure =
                shouldThrow<Exception> {
                    EngineWiring(
                        wiredDeploymentContext(),
                        scope,
                        module { single<SessionTimings> { SessionHarness.SHORT } },
                        listOf(provided(needy, listOf(Source::class), needs = HasChat::class)),
                    )
                }

            val messages = generateSequence<Throwable>(failure) { it.cause }.joinToString(" | ") { it.message.orEmpty() }
            messages shouldContain "TestSource needs HasChat"
        } finally {
            scope.cancel()
        }
    }

    test("an engine part that observes publications hears each publication the engine applied, with its roots") {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val observer = PublicationRecorder()
        val wiring =
            EngineWiring(
                wiredDeploymentContext(),
                scope,
                module { single<SessionTimings> { SessionHarness.SHORT } },
                listOf(provided(observer, listOf(PublicationObserver::class))),
            )
        try {
            wiring.applied(PublicationId(value = "first"), assemble(listOf(facts(resource(PAGE)), facts(resource(OTHER), root = OTHER))))
            wiring.applied(PublicationId(value = "second"), assemble(listOf(facts(resource(OTHER), root = OTHER))))

            observer.applied shouldBe
                listOf(
                    PublicationId(value = "first") to setOf(ResourceId("page"), ResourceId("other")),
                    PublicationId(value = "second") to setOf(ResourceId("other")),
                )
        } finally {
            wiring.close()
            scope.cancel()
        }
    }
}
