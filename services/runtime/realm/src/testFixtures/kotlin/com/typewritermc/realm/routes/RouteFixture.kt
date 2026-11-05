package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import kotlin.time.Duration.Companion.seconds

/** The session reply inbox prefix of the panel member whose requests the fixture delivers. */
internal const val PANEL_REPLY_INBOX = "_INBOX.member.0123456789abcdef0123456789abcdef"

internal class RouteFixture(
    routes: (RealmRouteScope, Communicator) -> CommunicatorRoutes,
) : AutoCloseable {
    val transport = FakeMessageTransport()
    private val telemetry = TelemetryTestHarness.create()
    private val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val address = RealmRouteScope(organizationId = "organization", realmId = "realm")
    private val router: CommunicatorRouter = communicator.createRouter(routes(address, communicator), scope)
    private var replySequence = 0

    init {
        runBlocking { router.start() shouldBe RouterResult.Success }
    }

    /** Sends [request] to the route of [contract] as the panel does and returns the decoded reply. */
    suspend fun <Request : Any, Response : Any> call(
        contract: RealmRouteScope.() -> UnaryContract<RealmRouteScope, Request, Response>,
        request: Request,
    ): Response =
        send(
            contract,
            address
                .contract()
                .requestCodec
                .encode(request)
                .toByteArray(),
        )

    /** Sends the raw [payload] to the route of [contract], as a client with a broken encoder would, and decodes the reply. */
    suspend fun <Response : Any> send(
        contract: RealmRouteScope.() -> UnaryContract<RealmRouteScope, *, Response>,
        payload: ByteArray,
    ): Response {
        val unary = address.contract()
        return unary.responseCodec.decode(exchange(unary.requestAddress.render(address), payload))
    }

    /** Opens the watch of [contract] with [request] and returns the initial reply the route answers with. */
    suspend fun <Request : Any, Initial : Any> watch(
        contract: RealmRouteScope.() -> WatchContract<RealmRouteScope, Request, Initial, *>,
        request: Request,
    ): Initial {
        val watch = address.contract()
        return watch.initialCodec.decode(exchange(watch.requestAddress.render(address), watch.requestCodec.encode(request).toByteArray()))
    }

    /** The events of [contract] the routes published so far, in order. */
    fun <Event : Any> events(contract: RealmRouteScope.() -> EventContract<RealmRouteScope, Event>): List<Event> {
        val event = address.contract()
        val to = event.address.render(address)
        return transport.actions
            .filterIsInstance<FakeMessageTransport.Action.Publish>()
            .filter { it.message.address == to }
            .map { event.codec.decode(it.message.payload) }
    }

    private suspend fun exchange(
        to: MessageAddress,
        payload: ByteArray,
    ): Payload = transport.exchange(to, payload, replyTo = MessageAddress.of("$PANEL_REPLY_INBOX.${replySequence++}"))

    override fun close() {
        runBlocking { router.stop() }
        scope.cancel()
        transport.close()
        telemetry.close()
    }
}
