package com.typewritermc.realm

import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import skirout.editor.v1.catalog.CatalogInvalidated
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

val RealmCatalogInvalidationProcessTest by testSuite {
    test("retries the installed generation announcement without a watch request") {
        runBlocking {
            val telemetry = TelemetryTestHarness.create()
            val transport = FakeMessageTransport()
            val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("initial")
            val process = RealmCatalogInvalidationProcess(catalogs, scope, telemetry.telemetry)
            try {
                transport.failNextPublish(TransportError.Unavailable())
                process.replaceCommunicator(
                    communicator,
                    RealmRouteScope(organizationId = "organization", realmId = "realm"),
                )

                val publication =
                    withTimeout(2.seconds) {
                        while (true) {
                            transport.actions
                                .filterIsInstance<FakeMessageTransport.Action.Publish>()
                                .filter {
                                    it.message.address ==
                                        MessageAddress.of(
                                            "service.from.realm.organization.organization.realm.editor.catalog.invalidate",
                                        )
                                }.takeIf { it.size >= 2 }
                                ?.last()
                                ?.let { return@withTimeout it }
                            delay(10.milliseconds)
                        }
                        error("Publication wait ended unexpectedly")
                    }
                val update = CatalogInvalidated.serializer.fromBytes(publication.message.payload.toByteArray())

                update.generation.value shouldBe "initial"
            } finally {
                process.stop()
                scope.cancel()
                catalogs.close()
                transport.close()
                telemetry.close()
            }
        }
    }

    test("announces the installed generation again when the communicator changes") {
        runBlocking {
            val telemetry = TelemetryTestHarness.create()
            val transport = FakeMessageTransport()
            val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
            val replacementTransport = FakeMessageTransport()
            val replacementCommunicator = Communicator(replacementTransport, telemetry.telemetry, ContextPropagators.noop())
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
            val catalogs = RealmCatalogStore()
            catalogs.installTestCatalog("a")
            val process = RealmCatalogInvalidationProcess(catalogs, scope, telemetry.telemetry)
            try {
                process.replaceCommunicator(
                    communicator,
                    RealmRouteScope(organizationId = "organization", realmId = "realm"),
                )
                val first = awaitPublicationCount(transport, 1)
                val firstUpdate = CatalogInvalidated.serializer.fromBytes(first.message.payload.toByteArray())

                process.replaceCommunicator(
                    replacementCommunicator,
                    RealmRouteScope(organizationId = "organization", realmId = "realm"),
                )
                val publication = awaitPublicationCount(replacementTransport, 1)
                val update = CatalogInvalidated.serializer.fromBytes(publication.message.payload.toByteArray())

                firstUpdate.generation.value shouldBe "a"
                update.generation.value shouldBe "a"
            } finally {
                process.stop()
                scope.cancel()
                catalogs.close()
                transport.close()
                replacementTransport.close()
                telemetry.close()
            }
        }
    }
}

private suspend fun awaitPublicationCount(
    transport: FakeMessageTransport,
    count: Int,
): FakeMessageTransport.Action.Publish =
    withTimeoutOrNull(2.seconds) {
        while (true) {
            transport.actions
                .filterIsInstance<FakeMessageTransport.Action.Publish>()
                .filter {
                    it.message.address ==
                        MessageAddress.of(
                            "service.from.realm.organization.organization.realm.editor.catalog.invalidate",
                        )
                }.takeIf { it.size >= count }
                ?.last()
                ?.let { return@withTimeoutOrNull it }
            delay(10.milliseconds)
        }
        error("Publication wait ended unexpectedly")
    } ?: error("Expected $count catalog invalidations but observed ${transport.actions}.")
