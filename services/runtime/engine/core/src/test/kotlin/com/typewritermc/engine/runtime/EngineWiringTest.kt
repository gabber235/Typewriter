package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.wiredDeploymentContext
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.readSessionEntry
import com.typewritermc.engine.session.testing.OnlineSet
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
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
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.dsl.module
import java.util.UUID
import kotlin.time.Duration.Companion.seconds

/** The Koin of one engine deployment: engine-core's session keeping, wired with the parts its engine kind brings. */
val EngineWiringTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("an engine deployment keeps the sessions its engine kind has as the engine the loader assigned it") {
        NatsTestServer.startWithJetStream().use { server ->
            onBroker(server.url) {
                val buckets = buckets()
                check(buckets.ensure(SessionsBucket.declaration("realm")) is KeyValueOpen.Opened)
                val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
                val online = OnlineSet()
                val wiring =
                    EngineWiring(
                        wiredDeploymentContext(buckets),
                        scope,
                        module {
                            single<SessionTimings> { SessionHarness.SHORT }
                            single<OnlineSessions> { online }
                        },
                    )
                try {
                    val uuid = UUID.randomUUID().toString()
                    val protagonist = Protagonist(PrincipalId(PrincipalId.MINECRAFT, uuid))

                    online.join(Session(protagonist, SessionId(uuid)))

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
            val failure =
                shouldThrow<Exception> { EngineWiring(wiredDeploymentContext(), scope, module { single<OnlineSessions> { OnlineSet() } }) }

            generateSequence<Throwable>(failure) { it.cause }.joinToString(" | ") { it.message.orEmpty() } shouldContain "SessionTimings"
        } finally {
            scope.cancel()
        }
    }
}
