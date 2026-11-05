@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.nats.NatsConnectionState
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleError
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.registrar.BindingObservation
import com.typewritermc.services.libs.registrar.BindingStatus
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.MessagingOperation
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarStopFailure
import com.typewritermc.services.libs.registrar.RegistrationLeaseResult
import com.typewritermc.services.libs.registrar.RuntimeCloseResult
import com.typewritermc.services.libs.registrar.RuntimeResult
import com.typewritermc.services.libs.registrar.RuntimeStopOperation
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.service.v1.lifecycle.ServiceHeartbeatNotification
import skirout.service.v1.lifecycle.ServiceShutdownNotification
import skirout.service.v1.registration.ServiceBoundNotification
import skirout.service.v1.status.EnsureRegistrationLeaseResponse
import skirout.service.v1.status.QueryServiceBindingResponse
import skirout.service.v1.status.ServiceBinding
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.TestTimeSource

val runtimeCredentials =
    IdentityCredentials(
        ServiceIdentity(ServiceId("service-id"), "Service Name", "service-user", ServiceRole.Custom("realm", "1.0.0")),
        RedactedSecret.AppPassword("app-password"),
    )

fun status(binding: ServiceBinding) = QueryServiceBindingResponse.createBinding(binding = binding)

fun queryResponse(
    response: QueryServiceBindingResponse,
): suspend (
    com.typewritermc.services.libs.communicator.transport.OutboundMessage,
    kotlin.time.Duration,
) -> TransportResult<InboundMessage> =
    { message, _ ->
        TransportResult.Success(
            InboundMessage(message.address, QueryServiceBindingResponse.serializer.toBytes(response).toByteArray()),
        )
    }

fun leaseResponse(
    response: EnsureRegistrationLeaseResponse,
): suspend (
    com.typewritermc.services.libs.communicator.transport.OutboundMessage,
    kotlin.time.Duration,
) -> TransportResult<InboundMessage> =
    { message, _ ->
        TransportResult.Success(
            InboundMessage(message.address, EnsureRegistrationLeaseResponse.serializer.toBytes(response).toByteArray()),
        )
    }

internal class FakeNatsLifecycle : NatsLifecycle {
    override val state = MutableStateFlow(NatsConnectionState.Connected)
    var connectResult: NatsLifecycleResult = NatsLifecycleResult.Success
    var reconnectResult: NatsLifecycleResult = NatsLifecycleResult.Success
    var shutdownResult: NatsLifecycleResult = NatsLifecycleResult.Success

    override suspend fun connect() = connectResult

    override suspend fun reconnect() = reconnectResult

    override suspend fun shutdown() = shutdownResult
}

internal data class RuntimeFixture(
    val runtime: TypewriterRegistrarRuntime,
    val transport: FakeMessageTransport,
    val nats: FakeNatsLifecycle,
    val harness: TelemetryTestHarness,
    val access: AccessTokenCache,
    val sentinel: SentinelCache,
    val tokenExchanges: () -> Int,
    val sentinelFetches: () -> Int,
) : AutoCloseable {
    override fun close() {
        transport.close()
        harness.close()
    }
}

internal suspend fun runtimeFixture(): RuntimeFixture {
    var exchanges = 0
    var fetches = 0
    val timeSource = TestTimeSource()
    val access =
        AccessTokenCache(
            runtimeCredentials,
            AccessTokenExchanger {
                exchanges++
                AccessTokenResult.Success(RedactedSecret.AccessToken("access-token"), 3600)
            },
            timeSource,
            1.minutes,
        )
    val sentinel =
        SentinelCache(
            SentinelProvider {
                fetches++
                SentinelResult.Success(
                    SentinelCredentials(
                        RedactedSecret.SentinelJwt("sentinel-jwt"),
                        RedactedSecret.SentinelSeed("sentinel-seed"),
                    ),
                )
            },
            1.hours,
            2.hours,
            timeSource,
        )
    access.get()
    sentinel.get()
    val transport = FakeMessageTransport()
    val harness = TelemetryTestHarness.create()
    val nats = FakeNatsLifecycle()
    return RuntimeFixture(
        TypewriterRegistrarRuntime(
            Communicator(transport, harness.telemetry, harness.openTelemetry.propagators),
            ServiceRouteScope("service-id"),
            nats,
            access,
            sentinel,
        ),
        transport,
        nats,
        harness,
        access,
        sentinel,
        { exchanges },
        { fetches },
    )
}
