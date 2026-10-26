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
    test("a failed catalog announcement is retried until delivered") {
        runTest {
            withInvalidations(backgroundScope, "initial") { process ->
                val transport = FakeMessageTransport()
                transport.failNextPublish(TransportError.Unavailable())

                process.replaceCommunicator(communicator(transport), ADDRESS)

                transport.announcements() shouldBe listOf("initial", "initial")
            }
        }
    }

    test("a replaced communicator receives the installed generation again") {
        runTest {
            withInvalidations(backgroundScope, "a") { process ->
                val first = FakeMessageTransport()
                val replacement = FakeMessageTransport()

                process.replaceCommunicator(communicator(first), ADDRESS)
                process.replaceCommunicator(communicator(replacement), ADDRESS)

                first.announcements() shouldBe listOf("a")
                replacement.announcements() shouldBe listOf("a")
            }
        }
    }
}

private val ADDRESS = RealmRouteScope(organizationId = "organization", realmId = "realm")

private val CATALOG_INVALIDATE =
    MessageAddress.of("service.from.realm.organization.organization.realm.editor.catalog.invalidate")

/** The invalidation process of a Realm that installed [generation], on [scope]; [test] gets communicators from it. */
private suspend fun withInvalidations(
    scope: CoroutineScope,
    generation: String,
    test: suspend InvalidationContext.(RealmCatalogInvalidationProcess) -> Unit,
) {
    val telemetry = TelemetryTestHarness.create()
    val catalogs = RealmCatalogStore().apply { installTestCatalog(generation) }
    // The retry waits in virtual time, so a long delay costs nothing and proves no wall clock is involved.
    val process =
        RealmCatalogInvalidationProcess(catalogs, scope, telemetry.telemetry, RetryPolicy.fixed(30.seconds), CoroutineDelayScheduler)
    val context = InvalidationContext(telemetry)
    try {
        context.test(process)
    } finally {
        process.stop()
        context.close()
        catalogs.close()
        telemetry.close()
    }
}

private class InvalidationContext(
    private val telemetry: TelemetryTestHarness,
) : AutoCloseable {
    private val transports = mutableListOf<FakeMessageTransport>()

    fun communicator(transport: FakeMessageTransport): Communicator {
        transports += transport
        return Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
    }

    override fun close() = transports.forEach(FakeMessageTransport::close)
}

/** The generations announced on [this] transport, failed attempts included, in order. */
private fun FakeMessageTransport.announcements(): List<String> =
    actions
        .filterIsInstance<FakeMessageTransport.Action.Publish>()
        .filter { it.message.address == CATALOG_INVALIDATE }
        .map {
            CatalogInvalidated.serializer
                .fromBytes(it.message.payload.toByteArray())
                .generation.value
        }
