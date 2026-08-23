package com.typewritermc.realm

import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.TypeCatalog
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
import skirout.editor.v1.catalog.CatalogWatchUpdate
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import com.typewritermc.discovery.CatalogGeneration as DiscoveryGeneration

val RealmCatalogInvalidationProcessTest by testSuite {
    test("retries snapshot changes without a watch request") {
        runBlocking {
            val telemetry = TelemetryTestHarness.create()
            val transport = FakeMessageTransport()
            val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
            val snapshots = RealmDiscoverySnapshotStore()
            val process = RealmCatalogInvalidationProcess(snapshots, scope, telemetry.telemetry)
            try {
                transport.failNextPublish(TransportError.Unavailable())
                process.replaceCommunicator(communicator, RealmAddress("realm", "organization"))

                snapshots.replace(snapshot("next"))

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
                val update = CatalogWatchUpdate.serializer.fromBytes(publication.message.payload.toByteArray())

                (update as CatalogWatchUpdate.InvalidatedWrapper).value.generation.value shouldBe "next"
            } finally {
                process.stop()
                scope.cancel()
                transport.close()
                telemetry.close()
            }
        }
    }

    test("publishes a rollback to the communicator baseline generation") {
        runBlocking {
            val telemetry = TelemetryTestHarness.create()
            val transport = FakeMessageTransport()
            val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
            val snapshots = RealmDiscoverySnapshotStore()
            val process = RealmCatalogInvalidationProcess(snapshots, scope, telemetry.telemetry)
            try {
                snapshots.replace(snapshot("a"))
                process.replaceCommunicator(communicator, RealmAddress("realm", "organization"))

                snapshots.replace(snapshot("b"))
                awaitPublicationCount(transport, 1)
                snapshots.replace(snapshot("a"))
                val publication = awaitPublicationCount(transport, 2)
                val update = CatalogWatchUpdate.serializer.fromBytes(publication.message.payload.toByteArray())

                (update as CatalogWatchUpdate.InvalidatedWrapper).value.generation.value shouldBe "a"
            } finally {
                process.stop()
                scope.cancel()
                transport.close()
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

private fun snapshot(generation: String): RealmDiscoverySnapshot =
    RealmDiscoverySnapshot(
        discovery =
            DeploymentDiscoverySnapshot(
                generation = DiscoveryGeneration(generation),
                artifacts = emptyList(),
                sourceParts = emptyList(),
                types = TypeCatalog(emptyList()),
                diagnostics = emptyList(),
            ),
        elements = ElementCatalog(emptyList()),
    )
