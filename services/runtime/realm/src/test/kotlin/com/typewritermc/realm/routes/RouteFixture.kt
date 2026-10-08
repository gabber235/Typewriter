package com.typewritermc.realm.routes

import build.skir.Serializer
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
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

internal class RouteFixture(
    routes: (EditorContracts, RealmAddress, Communicator) -> CommunicatorRoutes,
) : AutoCloseable {
    val transport = FakeMessageTransport()
    private val telemetry = TelemetryTestHarness.create()
    private val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val address = RealmAddress("realm", "organization")
    private val router: CommunicatorRouter = communicator.createRouter(routes(EditorContracts(address), address, communicator), scope)
    private var replySequence = 0

    init {
        runBlocking { router.start() shouldBe RouterResult.Success }
    }

    suspend fun <Request : Any, Response : Any> request(
        suffix: String,
        request: Request,
        requestSerializer: Serializer<Request>,
        responseSerializer: Serializer<Response>,
    ): Response = requestPayload(suffix, requestSerializer.toBytes(request).toByteArray(), responseSerializer)

    suspend fun <Response : Any> requestPayload(
        suffix: String,
        payload: ByteArray,
        responseSerializer: Serializer<Response>,
    ): Response {
        val reply = MessageAddress.of("test.reply.${replySequence++}")
        transport.deliver(
            TransportDelivery.Message(
                InboundMessage(
                    address = MessageAddress.of("service.to.realm.organization.organization.realm.$suffix"),
                    payload = payload,
                    replyTo = reply,
                ),
            ),
        )
        val publication =
            withTimeout(2.seconds) {
                while (true) {
                    transport.actions
                        .filterIsInstance<FakeMessageTransport.Action.Publish>()
                        .lastOrNull { it.message.address == reply }
                        ?.let { return@withTimeout it }
                    yield()
                }
                error("Reply wait ended unexpectedly")
            }
        return responseSerializer.fromBytes(publication.message.payload.toByteArray())
    }

    override fun close() {
        runBlocking { router.stop() }
        scope.cancel()
        transport.close()
        telemetry.close()
    }
}
