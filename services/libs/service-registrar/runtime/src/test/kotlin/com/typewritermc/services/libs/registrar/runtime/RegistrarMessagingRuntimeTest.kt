@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.services.libs.registrar.runtime

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
import com.typewritermc.services.libs.registrar.RuntimeCloseResult
import com.typewritermc.services.libs.registrar.RuntimeConnectivity
import com.typewritermc.services.libs.registrar.RuntimeResult
import com.typewritermc.services.libs.registrar.RuntimeStopOperation
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.access.v1.permission.EntityPermissionQualifier
import skirout.service.v1.lifecycle.ServiceHeartbeatNotification
import skirout.service.v1.lifecycle.ServiceShutdownNotification
import skirout.service.v1.registration.ServiceBoundNotification
import skirout.service.v1.status.GetServiceStatusResponse
import skirout.service.v1.status.ServiceBinding
import java.util.Base64
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.TimeSource

private val runtimeCredentials =
    IdentityCredentials(
        ServiceIdentity("service-id", "Service Name", "service-user", listOf(ServiceRole.Realm("1.0.0"))),
        RedactedSecret.AppPassword("app-password"),
    )

private class FakeNatsLifecycle : NatsLifecycle {
    override val state = MutableStateFlow(NatsConnectionState.Connected)
    var connectResult: NatsLifecycleResult = NatsLifecycleResult.Success
    var reconnectResult: NatsLifecycleResult = NatsLifecycleResult.Success
    var shutdownResult: NatsLifecycleResult = NatsLifecycleResult.Success

    override suspend fun connect() = connectResult

    override suspend fun reconnect() = reconnectResult

    override suspend fun shutdown() = shutdownResult
}

private data class RuntimeFixture(
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

private suspend fun runtimeFixture(): RuntimeFixture {
    var exchanges = 0
    var fetches = 0
    val access =
        AccessTokenCache(
            runtimeCredentials,
            AccessTokenExchanger {
                exchanges++
                AccessTokenResult.Success(RedactedSecret.AccessToken("access-token"), 3600)
            },
            TimeSource.Monotonic,
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
            TimeSource.Monotonic,
        )
    access.get()
    sentinel.get()
    val transport = FakeMessageTransport()
    val harness = TelemetryTestHarness.create()
    val nats = FakeNatsLifecycle()
    return RuntimeFixture(
        TypewriterRegistrarRuntime(
            Communicator(transport, harness.telemetry, harness.openTelemetry.propagators),
            ServiceAddress("service-id"),
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

private fun status(binding: ServiceBinding) = GetServiceStatusResponse.createStatus(binding = binding)

private fun response(
    response: GetServiceStatusResponse,
): suspend (
    com.typewritermc.services.libs.communicator.transport.OutboundMessage,
    kotlin.time.Duration,
) -> TransportResult<InboundMessage> =
    { message, _ ->
        TransportResult.Success(
            InboundMessage(message.address, GetServiceStatusResponse.serializer.toBytes(response).toByteArray()),
        )
    }

val RegistrarMessagingRuntimeTest by testSuite {
    test("query uses exact status subject and maps bound name") {
        val fixture = runtimeFixture()
        try {
            fixture.transport.respondWith(
                response(
                    status(
                        ServiceBinding.createBound(
                            organizationId = "organization-id",
                            organizationName = "Organization",
                        ),
                    ),
                ),
            )
            val result = fixture.runtime.queryBinding() as RuntimeResult.Success
            val bound = result.value as BindingStatus.Bound
            bound.binding.organizationId shouldBe "organization-id"
            bound.binding.organizationName shouldBe "Organization"
            val action =
                fixture.transport.actions
                    .filterIsInstance<FakeMessageTransport.Action.Request>()
                    .single()
            action.message.address.value shouldBe "cloud.to.service.service-id.status"
        } finally {
            fixture.close()
        }
    }

    test("query preserves a blank organization name") {
        val mapped =
            mapStatus(
                status(ServiceBinding.createBound(organizationId = "organization-id", organizationName = "")),
                MessagingOperation.BINDING_QUERY,
            ) as RuntimeResult.Success
        ((mapped.value as BindingStatus.Bound).binding.organizationName) shouldBe ""
    }

    test("unbound status preserves null token") {
        val mapped =
            mapStatus(
                status(ServiceBinding.createUnbound(registrationToken = null)),
                MessagingOperation.BINDING_QUERY,
            ) as RuntimeResult.Success
        (mapped.value as BindingStatus.Unbound).token shouldBe null
    }

    test("unbound status maps a valid token") {
        val mapped =
            mapStatus(
                status(ServiceBinding.createUnbound(registrationToken = "TOKEN12345")),
                MessagingOperation.BINDING_QUERY,
            ) as RuntimeResult.Success
        (mapped.value as BindingStatus.Unbound).token?.reveal() shouldBe "TOKEN12345"
    }

    test("blank registration token is protocol incompatible") {
        val mapped =
            mapStatus(
                status(ServiceBinding.createUnbound(registrationToken = "")),
                MessagingOperation.BINDING_QUERY,
            ) as RuntimeResult.Failure
        (mapped.failure is RegistrarFailure.ProtocolIncompatible) shouldBe true
    }

    test("service not found is terminal typed failure") {
        val mapped =
            mapStatus(
                GetServiceStatusResponse.createServiceNotFoundError(),
                MessagingOperation.BINDING_QUERY,
            ) as RuntimeResult.Failure
        mapped.failure shouldBe RegistrarFailure.ServiceNotFound
    }

    test("internal status is recoverable messaging failure for its operation") {
        val mapped =
            mapStatus(
                GetServiceStatusResponse.createInternalError(),
                MessagingOperation.BINDING_WATCH,
            ) as RuntimeResult.Failure
        mapped.failure shouldBe RegistrarFailure.Messaging(MessagingOperation.BINDING_WATCH)
    }

    test("unknown status and binding are protocol incompatible") {
        (mapStatus(GetServiceStatusResponse.UNKNOWN, MessagingOperation.BINDING_QUERY) as RuntimeResult.Failure)
            .failure
            .let { it is RegistrarFailure.ProtocolIncompatible } shouldBe true
        (mapBinding(ServiceBinding.UNKNOWN) as RuntimeResult.Failure)
            .failure
            .let { it is RegistrarFailure.ProtocolIncompatible } shouldBe true
    }

    test("watch subscribes to bound subject before status and maps initial then update") {
        runTest {
            val fixture = runtimeFixture()
            try {
                fixture.transport.respondWith(
                    response(status(ServiceBinding.createUnbound(registrationToken = "TOKEN12345"))),
                )
                val collected =
                    async {
                        fixture.runtime
                            .watchBinding()
                            .take(2)
                            .toList()
                    }
                runCurrent()
                fixture.transport.actions
                    .take(2)
                    .map { action ->
                        when (action) {
                            is FakeMessageTransport.Action.Subscribe -> "subscribe:${action.pattern.value}"
                            is FakeMessageTransport.Action.Request -> "request:${action.message.address.value}"
                            else -> "other"
                        }
                    }.shouldContainExactly(
                        "subscribe:cloud.from.service.service-id.registration.bound",
                        "request:cloud.to.service.service-id.status",
                    )
                val notification =
                    ServiceBoundNotification(
                        organizationId = "organization-id",
                        organizationName = "Organization",
                    )
                fixture.transport.deliver(
                    com.typewritermc.services.libs.communicator.transport.TransportDelivery.Message(
                        InboundMessage(
                            com.typewritermc.services.libs.communicator.address.MessageAddress.of(
                                "cloud.from.service.service-id.registration.bound",
                            ),
                            ServiceBoundNotification.serializer.toBytes(notification).toByteArray(),
                        ),
                    ),
                )
                val values = collected.await()
                val initial = (values[0] as RuntimeResult.Success).value as BindingObservation.Initial
                (initial.status as BindingStatus.Unbound).token?.reveal() shouldBe "TOKEN12345"
                val bound = (values[1] as RuntimeResult.Success).value as BindingObservation.Bound
                bound.binding.organizationId shouldBe "organization-id"
            } finally {
                fixture.close()
            }
        }
    }

    test("heartbeat publishes exact subject and canonical payload") {
        val fixture = runtimeFixture()
        try {
            fixture.runtime.sendHeartbeat() shouldBe RuntimeResult.Success(Unit)
            val published =
                fixture.transport.actions
                    .filterIsInstance<FakeMessageTransport.Action.Publish>()
                    .single()
            published.message.address.value shouldBe "cloud.to.service.service-id.heartbeat"
            ServiceHeartbeatNotification.serializer
                .fromBytes(published.message.payload)
                .shouldBe(ServiceHeartbeatNotification())
        } finally {
            fixture.close()
        }
    }

    test("shutdown publishes exact subject and reports shutdown operation failure") {
        val fixture = runtimeFixture()
        try {
            fixture.runtime.sendShutdown() shouldBe RuntimeResult.Success(Unit)
            val published =
                fixture.transport.actions
                    .filterIsInstance<FakeMessageTransport.Action.Publish>()
                    .single()
            published.message.address.value shouldBe "cloud.to.service.service-id.shutdown"
            ServiceShutdownNotification.serializer
                .fromBytes(published.message.payload)
                .shouldBe(ServiceShutdownNotification())
            fixture.transport.failNextPublish(TransportError.Unavailable())
            val failed = fixture.runtime.sendShutdown() as RuntimeResult.Failure
            failed.failure shouldBe RegistrarFailure.Messaging(MessagingOperation.SHUTDOWN)
        } finally {
            fixture.close()
        }
    }

    test("connect failure invalidates both credential caches") {
        val fixture = runtimeFixture()
        try {
            fixture.nats.connectResult =
                NatsLifecycleResult.Failure(
                    NatsLifecycleError.Connection(IllegalStateException("offline")),
                )
            (fixture.runtime.connect() is RuntimeResult.Failure) shouldBe true
            fixture.runtime.connectivity.first() shouldBe RuntimeConnectivity.CONNECTED
            val beforeTokens = fixture.tokenExchanges()
            val beforeSentinel = fixture.sentinelFetches()
            fixture.access.get()
            fixture.sentinel.get()
            fixture.tokenExchanges() shouldBe beforeTokens + 1
            fixture.sentinelFetches() shouldBe beforeSentinel + 1
        } finally {
            fixture.close()
        }
    }

    test("reconnect failure is recoverable messaging failure") {
        val fixture = runtimeFixture()
        try {
            fixture.nats.reconnectResult =
                NatsLifecycleResult.Failure(
                    NatsLifecycleError.Connection(IllegalStateException("offline")),
                )
            val result = fixture.runtime.reconnectForBoundPermissions() as RuntimeResult.Failure
            result.failure shouldBe RegistrarFailure.Messaging(MessagingOperation.REAUTHORIZE)
        } finally {
            fixture.close()
        }
    }

    test("close reports lifecycle shutdown failure") {
        val fixture = runtimeFixture()
        try {
            fixture.nats.shutdownResult =
                NatsLifecycleResult.Failure(
                    NatsLifecycleError.Shutdown(IllegalStateException("failed")),
                )
            val result = fixture.runtime.close() as RuntimeCloseResult.Failure
            result.failures.shouldContainExactly(
                RegistrarStopFailure.Runtime(RuntimeStopOperation.CLOSE_FAILED),
            )
        } finally {
            fixture.close()
        }
    }

    test("service qualifier uses standard base64 and round trips") {
        val encoded = encodedServiceQualifier()
        val decoded = Base64.getDecoder().decode(encoded)
        val qualifier = EntityPermissionQualifier.serializer.fromBytes(decoded)
        qualifier.kind shouldBe EntityPermissionQualifier.Kind.SERVICE_WRAPPER
    }

    test("service authentication maps exact fields and redacts diagnostics") {
        val authentication =
            createServiceAuthentication(
                true,
                { seed ->
                    seed shouldBe "sentinel-seed"
                    "signed-nonce"
                },
                RedactedSecret.AccessToken("access-token"),
                SentinelCredentials(
                    RedactedSecret.SentinelJwt("sentinel-jwt"),
                    RedactedSecret.SentinelSeed("sentinel-seed"),
                ),
            )
        authentication.username shouldBe null
        authentication.password shouldBe "access-token"
        authentication.jwt shouldBe "sentinel-jwt"
        authentication.signature shouldBe "signed-nonce"
        authentication.nkey shouldBe encodedServiceQualifier()
        authentication.toString().contains("access-token") shouldBe false
        authentication.toString().contains("sentinel-jwt") shouldBe false
    }

    test("service authentication requires nonce and signature") {
        shouldThrow<MissingNatsNonceException> {
            createServiceAuthentication(
                false,
                { "signature" },
                RedactedSecret.AccessToken("access-token"),
                SentinelCredentials(
                    RedactedSecret.SentinelJwt("sentinel-jwt"),
                    RedactedSecret.SentinelSeed("sentinel-seed"),
                ),
            )
        }
        shouldThrow<MissingNatsNonceException> {
            createServiceAuthentication(
                true,
                { null },
                RedactedSecret.AccessToken("access-token"),
                SentinelCredentials(
                    RedactedSecret.SentinelJwt("sentinel-jwt"),
                    RedactedSecret.SentinelSeed("sentinel-seed"),
                ),
            )
        }
    }
}
