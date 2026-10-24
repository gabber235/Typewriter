package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.protocol.transport.generated.ServiceRouteScope
import com.typewritermc.protocol.transport.generated.registrationLeaseEnsure
import com.typewritermc.protocol.transport.generated.serviceBindingQuery
import com.typewritermc.protocol.transport.generated.serviceHeartbeat
import com.typewritermc.protocol.transport.generated.serviceShutdown
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.contract.initialRequest
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionState
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.http.core.ServiceHttpClient
import com.typewritermc.services.libs.registrar.BindingObservation
import com.typewritermc.services.libs.registrar.BindingStatus
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.MessagingOperation
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.RegistrarCause
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarRuntime
import com.typewritermc.services.libs.registrar.RegistrarRuntimeFactory
import com.typewritermc.services.libs.registrar.RegistrarStopFailure
import com.typewritermc.services.libs.registrar.RegistrationLeaseResult
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
import skirout.service.v1.status.EnsureRegistrationLeaseRequest
import skirout.service.v1.status.EnsureRegistrationLeaseResponse
import skirout.service.v1.status.QueryServiceBindingRequest
import skirout.service.v1.status.QueryServiceBindingResponse
import skirout.service.v1.status.ServiceBinding
import kotlin.time.TimeSource

private val queryPolicy =
    ResponsePolicy<QueryServiceBindingResponse>(
        QueryServiceBindingResponse.createInternalError(),
        ResponseClassifier { response ->
            when (response.kind) {
                QueryServiceBindingResponse.Kind.BINDING_WRAPPER -> {
                    classification(ResponseOutcome.SUCCESS, "binding")
                }

                QueryServiceBindingResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
                    classification(
                        ResponseOutcome.DOMAIN_ERROR,
                        "service-not-found",
                    )
                }

                QueryServiceBindingResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
                    classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
                }

                QueryServiceBindingResponse.Kind.UNKNOWN -> {
                    classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
                }
            }
        },
    )
private val leasePolicy =
    ResponsePolicy<EnsureRegistrationLeaseResponse>(
        EnsureRegistrationLeaseResponse.createInternalError(),
        ResponseClassifier { response ->
            when (response.kind) {
                EnsureRegistrationLeaseResponse.Kind.ISSUED_WRAPPER -> {
                    classification(ResponseOutcome.SUCCESS, "issued")
                }

                EnsureRegistrationLeaseResponse.Kind.ALREADY_BOUND_WRAPPER -> {
                    classification(ResponseOutcome.SUCCESS, "already-bound")
                }

                EnsureRegistrationLeaseResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
                    classification(ResponseOutcome.DOMAIN_ERROR, "service-not-found")
                }

                EnsureRegistrationLeaseResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
                    classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
                }

                EnsureRegistrationLeaseResponse.Kind.UNKNOWN -> {
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

/**
 * Adapts NATS lifecycle and service protocol operations to registrar contracts.
 *
 * It maps binding, heartbeat, and shutdown failures without conflating unknown protocol variants with transient
 * connectivity. Closure shuts down NATS and clears authentication caches.
 */
internal class TypewriterRegistrarRuntime(
    override val communicator: Communicator,
    private val service: ServiceRouteScope,
    private val nats: NatsLifecycle,
    private val accessTokens: AccessTokenCache,
    private val sentinel: SentinelCache,
) : RegistrarRuntime {
    private val queryBindingContract = service.serviceBindingQuery(queryPolicy, boundClassifier)
    private val ensureLeaseContract = service.registrationLeaseEnsure(leasePolicy)
    private val heartbeatContract = service.serviceHeartbeat
    private val shutdownContract = service.serviceShutdown

    override val connectivity: Flow<RuntimeConnectivity> = nats.state.map(NatsConnectionState::toRuntimeConnectivity)
    override val currentConnectivity: RuntimeConnectivity
        get() = nats.state.value.toRuntimeConnectivity()

    override suspend fun connect() = lifecycle(MessagingOperation.CONNECT) { nats.connect() }

    override suspend fun reconnectForBoundPermissions() = lifecycle(MessagingOperation.REAUTHORIZE) { nats.reconnect() }

    override suspend fun queryBinding(): RuntimeResult<BindingStatus> =
        when (val result = communicator.request(queryBindingContract.initialRequest(), service, QueryServiceBindingRequest())) {
            is CommunicationResult.Failure -> messaging(MessagingOperation.BINDING_QUERY, result.error.cause)
            is CommunicationResult.Success -> mapQueryBinding(result.value)
        }

    override suspend fun ensureRegistrationLease(): RuntimeResult<RegistrationLeaseResult> =
        when (val result = communicator.request(ensureLeaseContract, service, EnsureRegistrationLeaseRequest())) {
            is CommunicationResult.Failure -> messaging(MessagingOperation.REGISTRATION_LEASE, result.error.cause)
            is CommunicationResult.Success -> mapRegistrationLease(result.value)
        }

    override fun watchBinding(): Flow<RuntimeResult<BindingObservation>> =
        communicator
            .watch(queryBindingContract, service, QueryServiceBindingRequest())
            .map { result ->
                when (result) {
                    is CommunicationResult.Failure -> {
                        messaging(MessagingOperation.BINDING_WATCH, result.error.cause)
                    }

                    is CommunicationResult.Success -> {
                        when (val message = result.value) {
                            is WatchMessage.Initial -> {
                                mapQueryBinding(message.value, MessagingOperation.BINDING_WATCH)
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
        return RuntimeResult.Failure(
            auth?.failure ?: RegistrarFailure.Messaging(operation, cause = RegistrarCause.from(cause)),
        )
    }

    private suspend fun <E : Any> publish(
        contract: EventContract<ServiceRouteScope, E>,
        event: E,
        operation: MessagingOperation,
    ) = when (val result = communicator.publish(contract, service, event)) {
        is CommunicationResult.Success -> RuntimeResult.Success(Unit)
        is CommunicationResult.Failure -> messaging(operation, result.error.cause)
    }
}

internal fun mapQueryBinding(
    response: QueryServiceBindingResponse,
    operation: MessagingOperation = MessagingOperation.BINDING_QUERY,
): RuntimeResult<BindingStatus> =
    when (response.kind) {
        QueryServiceBindingResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
            RuntimeResult.Failure(RegistrarFailure.ServiceNotFound)
        }

        QueryServiceBindingResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
            messaging(operation)
        }

        QueryServiceBindingResponse.Kind.UNKNOWN -> {
            RuntimeResult.Failure(RegistrarFailure.ProtocolIncompatible("service-status", "unknown"))
        }

        QueryServiceBindingResponse.Kind.BINDING_WRAPPER -> {
            mapBinding((response as QueryServiceBindingResponse.BindingWrapper).value.binding)
        }
    }

internal fun mapRegistrationLease(response: EnsureRegistrationLeaseResponse): RuntimeResult<RegistrationLeaseResult> =
    when (response.kind) {
        EnsureRegistrationLeaseResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> {
            RuntimeResult.Failure(RegistrarFailure.ServiceNotFound)
        }

        EnsureRegistrationLeaseResponse.Kind.INTERNAL_ERROR_WRAPPER -> {
            messaging(MessagingOperation.REGISTRATION_LEASE)
        }

        EnsureRegistrationLeaseResponse.Kind.UNKNOWN -> {
            RuntimeResult.Failure(RegistrarFailure.ProtocolIncompatible("registration-lease", "unknown"))
        }

        EnsureRegistrationLeaseResponse.Kind.ALREADY_BOUND_WRAPPER -> {
            val bound = response as EnsureRegistrationLeaseResponse.AlreadyBoundWrapper
            mapBound(bound.value.organizationId, bound.value.organizationName).map(RegistrationLeaseResult::AlreadyBound)
        }

        EnsureRegistrationLeaseResponse.Kind.ISSUED_WRAPPER -> {
            val token = (response as EnsureRegistrationLeaseResponse.IssuedWrapper).value.token
            if (token.isBlank()) {
                RuntimeResult.Failure(RegistrarFailure.ProtocolIncompatible("registration-lease", "blank-token"))
            } else {
                RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken(token)))
            }
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

        ServiceBinding.Kind.UNBOUND_CONST -> {
            RuntimeResult.Success(BindingStatus.Unbound)
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

private fun <V> messaging(
    operation: MessagingOperation,
    cause: Throwable? = null,
): RuntimeResult<V> = RuntimeResult.Failure(RegistrarFailure.Messaging(operation, cause = RegistrarCause.from(cause)))

internal class RegistrarAuthenticationException(
    val failure: RegistrarFailure,
) : RuntimeException(null, null, false, false)

/**
 * Acquires token and Sentinel material, then constructs the NATS backed registrar runtime.
 *
 * Setup progress exposes the authentication phase. Creating the runtime is separate from the supervisor connecting
 * it; returned runtime resources become registrar owned.
 */
class TypewriterRegistrarRuntimeFactory(
    private val configuration: RegistrarConfiguration,
    private val httpClient: ServiceHttpClient,
    private val telemetry: ServiceTelemetry,
    private val propagators: ContextPropagators,
    private val clock: TimeSource,
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
                ServiceRouteScope(credentials.identity.serviceId.value),
                ProductionNatsLifecycle(connection),
                access,
                sentinel,
            ),
        )
    }
}
