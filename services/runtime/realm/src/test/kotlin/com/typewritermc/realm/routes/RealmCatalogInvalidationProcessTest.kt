package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.CatalogInvalidated
import kotlin.time.Duration.Companion.seconds

val RealmCatalogInvalidationProcessTest by testSuite {
    val realmAddress = RealmRouteScope(organizationId = "organization", realmId = "realm")

    test("a failed catalog announcement is retried until delivered") {
        runTest {
            withInvalidations(backgroundScope, "initial") { process ->
                val transport = FakeMessageTransport()
                transport.failNextPublish(TransportError.Unavailable())

                process.replaceCommunicator(communicator(transport), realmAddress)

                transport.announcements() shouldBe listOf("initial", "initial")
            }
        }
    }

    test("a replaced communicator receives the installed generation again") {
        runTest {
            withInvalidations(backgroundScope, "a") { process ->
                val first = FakeMessageTransport()
                val replacement = FakeMessageTransport()

                process.replaceCommunicator(communicator(first), realmAddress)
                process.replaceCommunicator(communicator(replacement), realmAddress)

                first.announcements() shouldBe listOf("a")
                replacement.announcements() shouldBe listOf("a")
            }
        }
    }
}
