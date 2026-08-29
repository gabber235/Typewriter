package com.typewritermc.services.integration

import kotlinx.coroutines.flow.Flow

/** Stable identity assigned to one independently deployed third party integration. */
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

/** Identifies the Realm whose data and operations bound an integration session. */
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

/** Stable generated identifier for a query, command, or event contract. */
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

/**
 * Holds the secret presented by an integration service for authentication.
 *
 * String conversion is always redacted. Callers must still avoid logging or persisting [value] outside their credential
 * owner.
 */
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

/** Defines the Realm scoped authority that may be granted to an integration registration. */
enum class IntegrationPermission {
    REALM_READ,
    REALM_WRITE,
    EXECUTE,
    ADMINISTER,
    FILE_TRANSFER,
}

/** Separates request response operations from subscription events for permission and dispatch checks. */
enum class IntegrationOperationKind {
    QUERY,
    COMMAND,
    EVENT,
}

/** Captures the authoritative Realm scope and permissions granted to one integration identity. */
data class IntegrationRegistration(
    val id: IntegrationId,
    val realmId: IntegrationRealmId,
    val permissions: Set<IntegrationPermission>,
)

/** Carries authenticated integration identity across a transport boundary. */
data class IntegrationContext(
    val integrationId: IntegrationId,
    val realmId: IntegrationRealmId,
    val credential: IntegrationCredential,
)

/** Encodes one generated contract value without coupling the SDK core to a serialization format. */
interface IntegrationCodec<Value : Any> {
    fun encode(value: Value): ByteArray

    fun decode(bytes: ByteArray): Value
}

/**
 * Describes one generated query or command and the permission required to invoke it.
 *
 * Events use [IntegrationEvent]. Constructing a request operation with event kind fails immediately.
 */
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

/** Describes one generated event stream or publication and its required permission. */
class IntegrationEvent<Event : Any>(
    val id: IntegrationOperationId,
    val permission: IntegrationPermission,
    val codec: IntegrationCodec<Event>,
)

/**
 * Indexes generated operations and events for consistent client and server authorization.
 *
 * Duplicate identifiers within the same operation kind are rejected during construction. Unknown identifiers return no
 * permission and must never reach application dispatch.
 */
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

/** Makes authentication, authorization, contract lookup, and transport failures explicit to SDK callers. */
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

/**
 * Carries authenticated integration operations through a transport without weakening generated contract checks.
 *
 * Implementations preserve typed failures and propagate event stream cancellation to the caller.
 */
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
