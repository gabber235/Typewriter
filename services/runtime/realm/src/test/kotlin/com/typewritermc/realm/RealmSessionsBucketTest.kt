package com.typewritermc.realm

import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite

/**
 * The Realm owns its sessions bucket: engines of the Realm write their sessions into it once the Realm started. The
 * Realm runs on real time, since the broker answers on its own threads.
 */
val RealmSessionsBucketTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("REALM-S1 a started Realm creates its sessions bucket on the broker") {
        KeyValueStore.Broker.start().use { store ->
            val fixture = RealmLifecycleFixture(store.scope)
            try {
                fixture.messaging.value = fixture.session(1, buckets = store.connect()).session
                fixture.start()

                store.eventually { store.buckets.open("sessions_realm") is KeyValueOpen.Opened }
            } finally {
                fixture.close()
            }
        }
    }
}
