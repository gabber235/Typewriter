package com.typewritermc.realm

import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.onBroker
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlin.time.Duration.Companion.seconds

/**
 * The Realm owns its sessions bucket: engines of the Realm write their sessions into it once the Realm started. The
 * Realm runs on real time, since the broker answers on its own threads.
 */
val RealmSessionsBucketTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("REALM-S1 a started Realm creates its sessions bucket on the broker") {
        NatsTestServer.startWithJetStream().use { server ->
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
            val fixture = RealmLifecycleFixture(scope)
            try {
                onBroker(server.url) {
                    fixture.messaging.value = fixture.session(1, buckets = buckets()).session
                    fixture.start()

                    val observer = buckets()
                    eventually(10.seconds) {
                        observer.open("sessions_realm").shouldBeInstanceOf<KeyValueOpen.Opened>()
                    }
                }
            } finally {
                fixture.close()
                scope.cancel()
            }
        }
    }
}
