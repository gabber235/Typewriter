package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.testing.wiredDeploymentContext
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.testing.OnlineSet
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.string.shouldContain
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.dsl.module

/** The Koin of one engine deployment: engine-core's session keeping, wired with the parts its engine kind brings. */
val EngineWiringTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("an engine deployment keeps the sessions its engine kind has as the engine the loader assigned it") {
        SessionHarness(KeyValueStore.Broker.start(), SessionHarness.BROKER).use { sessions ->
            sessions.createBucket()
            val online = OnlineSet()
            val wiring =
                EngineWiring(
                    wiredDeploymentContext(sessions.store.connect()),
                    sessions.store.scope,
                    module {
                        single<SessionTimings> { sessions.timings }
                        single<OnlineSessions> { online }
                    },
                )
            wiring.use {
                val session = sessions.player()

                online.join(session)

                sessions.store.eventually { sessions.entry(session.protagonist, session.id)?.holder == EngineId("engine") }
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
