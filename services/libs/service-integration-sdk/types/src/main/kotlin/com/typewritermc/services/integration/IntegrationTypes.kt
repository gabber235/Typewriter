package com.typewritermc.services.integration

import kotlinx.coroutines.flow.Flow

@JvmInline
value class IntegrationId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): IntegrationId {
            require(identifierPattern.matches(value)) { "Invalid integration id" }
            return IntegrationId(value)
        }
    }
}

@JvmInline
value class IntegrationRealmId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): IntegrationRealmId {
            require(identifierPattern.matches(value)) { "Invalid Realm id" }
            return IntegrationRealmId(value)
        }
    }
}

@JvmInline
value class IntegrationOperationId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): IntegrationOperationId {
            require(identifierPattern.matches(value)) { "Invalid integration operation id" }
            return IntegrationOperationId(value)
        }
    }
}

@JvmInline
value class IntegrationCredential private constructor(
    val value: String,
) {
    override fun toString(): String = "IntegrationCredential(redacted)"

    companion object {
        fun of(value: String): IntegrationCredential {
            require(value.isNotBlank() && value.length <= 4096) { "Invalid integration credential" }
            return IntegrationCredential(value)
        }
    }
}

enum class IntegrationPermission {
    REALM_READ,
    REALM_WRITE,
    EXECUTE,
    ADMINISTER,
    FILE_TRANSFER,
}

enum class IntegrationOperationKind {
    QUERY,
    COMMAND,
    EVENT,
}

data class IntegrationRegistration(
    val id: IntegrationId,
    val realmId: IntegrationRealmId,
    val permissions: Set<IntegrationPermission>,
)

data class IntegrationContext(
    val integrationId: IntegrationId,
    val realmId: IntegrationRealmId,
    val credential: IntegrationCredential,
)

interface IntegrationCodec<Value : Any> {
    fun encode(value: Value): ByteArray

    fun decode(bytes: ByteArray): Value
}

class IntegrationOperation<Request : Any, Response : Any>(
    val id: IntegrationOperationId,
    val kind: IntegrationOperationKind,
    val permission: IntegrationPermission,
    val requestCodec: IntegrationCodec<Request>,
    val responseCodec: IntegrationCodec<Response>,
) {
    init {
        require(kind != IntegrationOperationKind.EVENT) { "Request operations cannot be events" }
    }
}

class IntegrationEvent<Event : Any>(
    val id: IntegrationOperationId,
    val permission: IntegrationPermission,
    val codec: IntegrationCodec<Event>,
)

class GeneratedIntegrationContract(
    operations: Collection<IntegrationOperation<*, *>>,
    events: Collection<IntegrationEvent<*>>,
) {
    private val permissions =
        buildMap {
            operations.forEach { operation ->
                require(put(operation.kind to operation.id, operation.permission) == null) {
                    "Duplicate integration operation ${operation.id.value}"
                }
            }
            events.forEach { event ->
                require(put(IntegrationOperationKind.EVENT to event.id, event.permission) == null) {
                    "Duplicate integration event ${event.id.value}"
                }
            }
        }

    fun requiredPermission(
        kind: IntegrationOperationKind,
        id: IntegrationOperationId,
    ): IntegrationPermission? = permissions[kind to id]
}

sealed interface IntegrationResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : IntegrationResult<Value>

    data class PermissionDenied(
        val required: IntegrationPermission,
    ) : IntegrationResult<Nothing>

    data class UnknownOperation(
        val kind: IntegrationOperationKind,
        val id: IntegrationOperationId,
    ) : IntegrationResult<Nothing>

    data object AuthenticationFailed : IntegrationResult<Nothing>

    data class TransportFailure(
        val message: String,
        val cause: Throwable? = null,
    ) : IntegrationResult<Nothing>
}

interface IntegrationGateway {
    suspend fun request(
        context: IntegrationContext,
        kind: IntegrationOperationKind,
        operationId: IntegrationOperationId,
        payload: ByteArray,
    ): IntegrationResult<ByteArray>

    suspend fun publish(
        context: IntegrationContext,
        eventId: IntegrationOperationId,
        payload: ByteArray,
    ): IntegrationResult<Unit>

    fun events(
        context: IntegrationContext,
        eventId: IntegrationOperationId,
    ): Flow<IntegrationResult<ByteArray>>
}

private val identifierPattern = Regex("[A-Za-z0-9][A-Za-z0-9._:-]{0,254}")
