package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.testing.LaggingNatsClient
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

/** The adapter over a real natskt client. */
val NatsClientAdapterTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("a client that connected reports itself connected when connect returns") {
        val client = LaggingNatsClient()
        val adapter = RealNatsClientAdapter(client)

        val connected = adapter.connect()
        val connectivity = adapter.connectivity.value

        connected.isSuccess shouldBe true
        connectivity shouldBe NatsClientConnectivity.Connected

        client.close()
    }
}
