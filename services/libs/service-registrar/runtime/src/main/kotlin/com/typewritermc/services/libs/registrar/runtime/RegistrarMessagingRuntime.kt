package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionState
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.skir.asPayloadCodec
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.http.core.ServiceHttpClient
import com.typewritermc.services.libs.registrar.BindingObservation
import com.typewritermc.services.libs.registrar.BindingStatus
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.MessagingOperation
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarRuntime
import com.typewritermc.services.libs.registrar.RegistrarRuntimeFactory
import com.typewritermc.services.libs.registrar.RegistrarStopFailure
import com.typewritermc.services.libs.registrar.RegistrationToken
import com.typewritermc.services.libs.registrar.RuntimeCloseResult
import com.typewritermc.services.libs.registrar.RuntimeConnectivity
import com.typewritermc.services.libs.registrar.RuntimeCreateResult
import com.typewritermc.services.libs.registrar.RuntimeResult
import com.typewritermc.services.libs.registrar.RuntimeSetupProgress
import com.typewritermc.services.libs.registrar.RuntimeSetupProgressSink
import com.typewritermc.services.libs.registrar.RuntimeStopOperation
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import skirout.service.v1.lifecycle.ServiceHeartbeatNotification
import skirout.service.v1.lifecycle.ServiceShutdownNotification
import skirout.service.v1.registration.ServiceBoundNotification
import skirout.service.v1.status.GetServiceStatus
import skirout.service.v1.status.GetServiceStatusRequest
import skirout.service.v1.status.GetServiceStatusResponse
import skirout.service.v1.status.ServiceBinding
import kotlin.time.TimeSource

@JvmInline
value class ServiceAddress(
    val serviceId: String,
) {
    init {
        require(serviceId.isNotBlank())
    }
}

private fun serviceAddress(pattern: String): AddressTemplate<ServiceAddress> =
    addressTemplate(
        pattern,
        { addressValuesOf("id" to it.serviceId) },
        { ServiceAddress(it.require("id")) },
    )

val serviceStatusAddress = serviceAddress("cloud.to.service.{id}.status")
val serviceBoundAddress = serviceAddress("cloud.from.service.{id}.registration.bound")
val serviceHeartbeatAddress = serviceAddress("cloud.to.service.{id}.heartbeat")
val serviceShutdownAddress = serviceAddress("cloud.to.service.{id}.shutdown")

private val statusPolicy =
    ResponsePolicy<GetServiceStatusResponse>(
        GetServiceStatusResponse.createInternalError(),
        ResponseClassifier { response ->
            when (response.kind) {
                GetServiceStatusResponse.Kind.STATUS_WRAPPER -> {
                    classification(ResponseOutcome.SUCCESS, "status")
                }

                GetServiceStatusResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
                    classification(
                        ResponseOutcome.DOMAIN_ERROR,
                        "service-not-found",
                    )
                }

                GetServiceStatusResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
                    classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
                }

                GetServiceStatusResponse.Kind.UNKNOWN -> {
                    classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
                }
            }
        },
    )
private val boundClassifier = ResponseClassifier<ServiceBoundNotification> { classification(ResponseOutcome.SUCCESS, "bound") }

private fun classification(
    outcome: ResponseOutcome,
    variant: String,
) = ResponseClassification(outcome, ResponseVariant.of(variant))

private val statusContract =
    skirUnaryContract(
        GetServiceStatus,
        OperationName.of("registrar.status"),
        serviceStatusAddress,
        statusPolicy,
        ErrorSlug.of("registrar-status-failed"),
    )
private val bindingContract =
    skirWatchContract(
        GetServiceStatus,
        ServiceBoundNotification.serializer,
        OperationName.of("registrar.binding"),
        serviceStatusAddress,
        serviceBoundAddress,
        statusPolicy,
        boundClassifier,
        ErrorSlug.of("registrar-binding-failed"),
    )
private val heartbeatContract =
    EventContract(
        OperationName.of("registrar.heartbeat"),
        serviceHeartbeatAddress,
        ServiceHeartbeatNotification.serializer.asPayloadCodec(),
        ErrorSlug.of("registrar-heartbeat-failed"),
    )
private val shutdownContract =
    EventContract(
        OperationName.of("registrar.shutdown"),
        serviceShutdownAddress,
        ServiceShutdownNotification.serializer.asPayloadCodec(),
        ErrorSlug.of("registrar-shutdown-failed"),
    )

internal interface NatsLifecycle {
    val state: StateFlow<NatsConnectionState>

    suspend fun connect(): NatsLifecycleResult

    suspend fun reconnect(): NatsLifecycleResult

    suspend fun shutdown(): NatsLifecycleResult
}

private class ProductionNatsLifecycle(
    private val connection: NatsConnection,
) : NatsLifecycle {
    override val state = connection.state

    override suspend fun connect() = connection.connect()

    override suspend fun reconnect() = connection.reconnect()

    override suspend fun shutdown() = connection.shutdown()
}

private fun NatsConnectionState.toRuntimeConnectivity(): RuntimeConnectivity =
    when (this) {
        NatsConnectionState.Connected -> RuntimeConnectivity.CONNECTED
        NatsConnectionState.Connecting, NatsConnectionState.Reconnecting -> RuntimeConnectivity.CONNECTING
        NatsConnectionState.Disconnected, NatsConnectionState.ShuttingDown -> RuntimeConnectivity.DISCONNECTED
    }

internal class TypewriterRegistrarRuntime(
    override val communicator: Communicator,
    private val service: ServiceAddress,
    private val nats: NatsLifecycle,
    private val accessTokens: AccessTokenCache,
    private val sentinel: SentinelCache,
) : RegistrarRuntime {
    override val connectivity: Flow<RuntimeConnectivity> = nats.state.map(NatsConnectionState::toRuntimeConnectivity)
    override val currentConnectivity: RuntimeConnectivity
        get() = nats.state.value.toRuntimeConnectivity()

    override suspend fun connect() = lifecycle(MessagingOperation.CONNECT) { nats.connect() }

    override suspend fun reconnectForBoundPermissions() = lifecycle(MessagingOperation.REAUTHORIZE) { nats.reconnect() }

    override suspend fun queryBinding(): RuntimeResult<BindingStatus> =
        when (val result = communicator.request(statusContract, service, GetServiceStatusRequest())) {
            is CommunicationResult.Failure -> messaging(MessagingOperation.BINDING_QUERY)
            is CommunicationResult.Success -> mapStatus(result.value, MessagingOperation.BINDING_QUERY)
        }

    override fun watchBinding(): Flow<RuntimeResult<BindingObservation>> =
        communicator
            .watch(bindingContract, service, GetServiceStatusRequest())
            .map { result ->
                when (result) {
                    is CommunicationResult.Failure -> {
                        messaging(MessagingOperation.BINDING_WATCH)
                    }

                    is CommunicationResult.Success -> {
                        when (val message = result.value) {
                            is WatchMessage.Initial -> {
                                mapStatus(message.value, MessagingOperation.BINDING_WATCH)
                                    .map { BindingObservation.Initial(it) }
                            }

                            is WatchMessage.Update -> {
                                mapBound(message.value).map { BindingObservation.Bound(it) }
                            }
                        }
                    }
                }
            }

    override suspend fun sendHeartbeat() = publish(heartbeatContract, ServiceHeartbeatNotification(), MessagingOperation.HEARTBEAT)

    override suspend fun sendShutdown() = publish(shutdownContract, ServiceShutdownNotification(), MessagingOperation.SHUTDOWN)

    override suspend fun close(): RuntimeCloseResult {
        val failures = mutableListOf<RegistrarStopFailure>()
        if (nats.shutdown() is NatsLifecycleResult.Failure) {
            failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.CLOSE_FAILED)
        }
        accessTokens.clear()
        sentinel.clear()
        return if (failures.isEmpty()) RuntimeCloseResult.Success else RuntimeCloseResult.Failure(failures)
    }

    private suspend fun lifecycle(
        operation: MessagingOperation,
        action: suspend () -> NatsLifecycleResult,
    ): RuntimeResult<Unit> {
        val result =
            try {
                action()
            } catch (failure: RegistrarAuthenticationException) {
                return RuntimeResult.Failure(failure.failure)
            }
        if (result is NatsLifecycleResult.Success) return RuntimeResult.Success(Unit)
        accessTokens.invalidate()
        sentinel.invalidate()
        val cause = (result as NatsLifecycleResult.Failure).error.cause
        val auth = generateSequence(cause as Throwable?) { it.cause }.filterIsInstance<RegistrarAuthenticationException>().firstOrNull()
        return RuntimeResult.Failure(auth?.failure ?: RegistrarFailure.Messaging(operation))
    }

    private suspend fun <E : Any> publish(
        contract: EventContract<ServiceAddress, E>,
        event: E,
        operation: MessagingOperation,
    ) = when (communicator.publish(contract, service, event)) {
        is CommunicationResult.Success -> RuntimeResult.Success(Unit)
        is CommunicationResult.Failure -> messaging(operation)
    }
}

internal fun mapStatus(
    response: GetServiceStatusResponse,
    operation: MessagingOperation,
): RuntimeResult<BindingStatus> =
    when (response.kind) {
        GetServiceStatusResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
            RuntimeResult.Failure(RegistrarFailure.ServiceNotFound)
        }

        GetServiceStatusResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
            messaging(operation)
        }

        GetServiceStatusResponse.Kind.UNKNOWN -> {
            RuntimeResult.Failure(RegistrarFailure.ProtocolIncompatible("service-status", "unknown"))
        }

        GetServiceStatusResponse.Kind.STATUS_WRAPPER -> {
            mapBinding((response as GetServiceStatusResponse.StatusWrapper).value.binding)
        }
    }

internal fun mapBinding(binding: ServiceBinding): RuntimeResult<BindingStatus> =
    when (binding.kind) {
        ServiceBinding.Kind.UNKNOWN -> {
            RuntimeResult.Failure(RegistrarFailure.ProtocolIncompatible("service-binding", "unknown"))
        }

        ServiceBinding.Kind.BOUND_WRAPPER -> {
            val value = (binding as ServiceBinding.BoundWrapper).value
            mapBound(value.organizationId, value.organizationName).map { BindingStatus.Bound(it) }
        }

        ServiceBinding.Kind.UNBOUND_WRAPPER -> {
            val token = (binding as ServiceBinding.UnboundWrapper).value.registrationToken
            when {
                token == null -> {
                    RuntimeResult.Success(BindingStatus.Unbound(null))
                }

                token.isBlank() -> {
                    RuntimeResult.Failure(
                        RegistrarFailure.ProtocolIncompatible("service-binding", "blank-registration-token"),
                    )
                }

                else -> {
                    RuntimeResult.Success(BindingStatus.Unbound(RegistrationToken(token)))
                }
            }
        }
    }

internal fun mapBound(notification: ServiceBoundNotification) = mapBound(notification.organizationId, notification.organizationName)

private fun mapBound(
    id: String,
    name: String?,
): RuntimeResult<OrganizationBinding> {
    if (id.isBlank() || id != id.trim()) {
        return RuntimeResult.Failure(
            RegistrarFailure.ProtocolIncompatible("service-bound", "invalid-organization-id"),
        )
    }
    return RuntimeResult.Success(OrganizationBinding(id, name))
}

private fun <A, B> RuntimeResult<A>.map(transform: (A) -> B): RuntimeResult<B> =
    when (this) {
        is RuntimeResult.Success -> RuntimeResult.Success(transform(value))
        is RuntimeResult.Failure -> this
    }

private fun <V> messaging(operation: MessagingOperation): RuntimeResult<V> = RuntimeResult.Failure(RegistrarFailure.Messaging(operation))

internal class RegistrarAuthenticationException(
    val failure: RegistrarFailure,
) : RuntimeException(null, null, false, false)

class TypewriterRegistrarRuntimeFactory(
    private val configuration: RegistrarConfiguration,
    private val httpClient: ServiceHttpClient,
    private val telemetry: ServiceTelemetry,
    private val propagators: ContextPropagators,
    private val clock: TimeSource = TimeSource.Monotonic,
) : RegistrarRuntimeFactory {
    override suspend fun create(
        credentials: IdentityCredentials,
        progress: RuntimeSetupProgressSink,
    ): RuntimeCreateResult {
        val exchanger =
            AuthentikTokenExchanger(httpClient, configuration.oauthTokenUri, configuration.oauthClientId, configuration.oauthScopes)
        val access = AccessTokenCache(credentials, exchanger, clock, configuration.accessTokenRefreshSkew)
        val sentinel =
            SentinelCache(
                TypewriterSentinelProvider(httpClient, configuration.sentinelCredentialsUri),
                configuration.sentinelRefreshAfter,
                configuration.sentinelMaximumStaleness,
                clock,
            )
        progress.report(RuntimeSetupProgress.ACQUIRING_ACCESS_TOKEN)
        when (val result = access.get()) {
            is AccessTokenResult.Failure -> return RuntimeCreateResult.Failure(result.failure)
            else -> Unit
        }
        progress.report(RuntimeSetupProgress.ACQUIRING_SENTINEL_CREDENTIALS)
        when (val result = sentinel.get()) {
            is SentinelResult.Failure -> return RuntimeCreateResult.Failure(result.failure)
            else -> Unit
        }
        val connection =
            NatsConnection(
                { serviceNatsConfiguration(configuration, credentials) },
                serviceNatsAuthenticationProvider(access, sentinel, credentials),
            )
        val communicator = Communicator(NatsMessageTransport(connection), telemetry, propagators)
        progress.report(RuntimeSetupProgress.CONNECTING)
        return RuntimeCreateResult.Success(
            TypewriterRegistrarRuntime(
                communicator,
                ServiceAddress(credentials.identity.serviceId),
                ProductionNatsLifecycle(connection),
                access,
                sentinel,
            ),
        )
    }
}
