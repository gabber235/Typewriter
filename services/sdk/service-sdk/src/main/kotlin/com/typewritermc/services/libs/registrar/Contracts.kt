package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.client.Communicator
import kotlinx.coroutines.flow.Flow
import kotlin.time.Duration

/**
 * Returns an expected registration outcome without requiring exception based control flow.
 *
 * Cancellation and fatal runtime failures remain exceptional and are not ordinary retryable results.
 */
sealed interface RegistrarResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : RegistrarResult<Value>

    data class Failure(
        val failure: RegistrarFailure,
    ) : RegistrarResult<Nothing>
}

/**
 * Classifies registration failure by boundary and retry policy.
 *
 * Recoverability is explicit where retry can help. Protocol incompatibility and ambiguous identity issuance
 * require different handling from transient connectivity loss. Causes are wrapped for deliberate disclosure.
 */
sealed interface RegistrarFailure {
    data class Configuration(
        val slug: String,
    ) : RegistrarFailure

    data class CredentialStorage(
        val error: CredentialStorageError,
    ) : RegistrarFailure

    data class IdentityIssuance(
        val reason: IdentityIssueError,
    ) : RegistrarFailure

    data class AccessToken(
        val reason: AccessTokenFailureReason,
        val recoverable: Boolean,
    ) : RegistrarFailure

    data class Sentinel(
        val reason: SentinelFailureReason,
        val recoverable: Boolean,
    ) : RegistrarFailure

    data class Messaging(
        val operation: MessagingOperation,
        val recoverable: Boolean = true,
        val cause: RegistrarCause? = null,
    ) : RegistrarFailure

    data object ServiceNotFound : RegistrarFailure

    data class ProtocolIncompatible(
        val operation: String,
        val variant: String,
    ) : RegistrarFailure

    data class Internal(
        val slug: String,
    ) : RegistrarFailure
}

/** Preserved failure cause whose diagnostics are redacted unless deliberately revealed. */
class RegistrarCause private constructor(
    private val failure: Throwable,
) {
    fun reveal(): Throwable = failure

    override fun equals(other: Any?): Boolean = other is RegistrarCause && failure === other.failure

    override fun hashCode(): Int = System.identityHashCode(failure)

    override fun toString(): String = "[REDACTED]"

    companion object {
        fun from(failure: Throwable?): RegistrarCause? = failure?.let(::RegistrarCause)
    }
}

/** Explains whether access token acquisition failed transiently, by rejection, or by payload incompatibility. */
enum class AccessTokenFailureReason { UNAVAILABLE, REJECTED, PROTOCOL }

/** Explains why Sentinel credentials could not be refreshed, including stale fallback exhaustion. */
enum class SentinelFailureReason { UNAVAILABLE, REJECTED, PROTOCOL, STALE }

enum class MessagingOperation {
    RUNTIME_CREATE,
    CONNECT,
    BINDING_WATCH,
    BINDING_QUERY,
    REGISTRATION_LEASE,
    REAUTHORIZE,
    HEARTBEAT,
    SHUTDOWN,
    CONNECTIVITY,
}

enum class RuntimeStopOperation {
    COORDINATOR_TIMEOUT,
    SHUTDOWN_TIMEOUT,
    SHUTDOWN_THROWN,
    SHUTDOWN_FAILED,
    CLOSE_TIMEOUT,
    CLOSE_THROWN,
    CLOSE_FAILED,
}

/** Describes the next recovery attempt exposed in degraded registrar state. */
data class RetrySchedule(
    val attempt: Long,
    val delay: Duration,
)

enum class RegistrarStage {
    STORAGE,
    ACCESS_TOKEN,
    SENTINEL,
    CONNECTING,
    BINDING,
    REAUTHORIZING,
    HEARTBEAT,
}

sealed interface RegistrarStopFailure {
    data class Runtime(
        val operation: RuntimeStopOperation,
    ) : RegistrarStopFailure

    data class Internal(
        val slug: String,
    ) : RegistrarStopFailure
}

sealed interface RegistrarStopResult {
    data object Success : RegistrarStopResult

    data class Failure(
        val failures: List<RegistrarStopFailure>,
    ) : RegistrarStopResult
}

sealed interface CredentialStorageError {
    val recoverable: Boolean

    data class Unavailable(
        val slug: String,
    ) : CredentialStorageError {
        override val recoverable = true
    }

    data class Corrupt(
        val slug: String,
    ) : CredentialStorageError {
        override val recoverable = false
    }

    data class UnsupportedVersion(
        val version: Int,
    ) : CredentialStorageError {
        override val recoverable = false
    }
}

/** Distinguishes absent credentials from credentials that cannot safely be reused. */
sealed interface CredentialLoadResult {
    data object Missing : CredentialLoadResult

    data class Loaded(
        val credentials: IdentityCredentials,
    ) : CredentialLoadResult

    data class Failure(
        val error: CredentialStorageError,
    ) : CredentialLoadResult
}

/** Reports whether newly issued credentials were durably persisted. */
sealed interface CredentialStoreResult {
    data object Success : CredentialStoreResult

    data class Failure(
        val error: CredentialStorageError,
    ) : CredentialStoreResult
}

/**
 * Owns durable identity credentials across registrar restarts.
 *
 * Missing storage permits initial issuance; corrupt or unsupported storage must remain distinguishable from
 * missing data to avoid silently creating another identity.
 */
interface CredentialStorage {
    suspend fun load(): CredentialLoadResult

    suspend fun store(credentials: IdentityCredentials): CredentialStoreResult
}

enum class IdentityRejectionReason {
    MALFORMED_REQUEST,
    UNKNOWN_ROLE,
    ROLE_UNKNOWN_PROPERTY,
    ROLE_TYPE_INVALID,
    ROLE_VERSION_INVALID,
    CUSTOM_ROLE_NAME_REQUIRED,
    CUSTOM_ROLE_NAME_INVALID,
    BUILTIN_ROLE_NAME_FORBIDDEN,
}

/**
 * Reports whether identity issuance failed definitively or may have succeeded remotely.
 *
 * When [outcomeMayBeAmbiguous] is true, automatic reissuance can create another identity. The registrar exposes an
 * explicit unknown outcome state instead of treating this as a normal retry.
 */
sealed interface IdentityIssueError {
    val outcomeMayBeAmbiguous: Boolean

    data class Rejected(
        val reason: IdentityRejectionReason,
    ) : IdentityIssueError {
        override val outcomeMayBeAmbiguous = false
    }

    data class Unavailable(
        override val outcomeMayBeAmbiguous: Boolean,
    ) : IdentityIssueError

    data class Protocol(
        val variant: String,
        override val outcomeMayBeAmbiguous: Boolean,
    ) : IdentityIssueError
}

sealed interface IdentityIssueResult {
    data class Success(
        val credentials: IdentityCredentials,
    ) : IdentityIssueResult

    data class Failure(
        val error: IdentityIssueError,
    ) : IdentityIssueResult
}

/** Issues credentials for a role without retrying an operation whose remote outcome may be ambiguous. */
fun interface IdentityIssuer {
    suspend fun issue(role: ServiceRole): IdentityIssueResult
}

enum class RuntimeConnectivity { DISCONNECTED, CONNECTING, CONNECTED }

/** Result returned by runtime operations, with failures classified for registrar recovery. */
sealed interface RuntimeResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : RuntimeResult<Value>

    data class Failure(
        val failure: RegistrarFailure,
    ) : RuntimeResult<Nothing>
}

/** Current organization binding observed without creating or renewing a registration lease. */
sealed interface BindingStatus {
    data object Unbound : BindingStatus

    data class Bound(
        val binding: OrganizationBinding,
    ) : BindingStatus
}

/** Result of explicitly ensuring the operator registration lease. */
sealed interface RegistrationLeaseResult {
    data class Issued(
        val token: RegistrationToken,
    ) : RegistrationLeaseResult

    data class AlreadyBound(
        val binding: OrganizationBinding,
    ) : RegistrationLeaseResult
}

/** Initial or subsequent binding information emitted by a runtime watch. */
sealed interface BindingObservation {
    data class Initial(
        val status: BindingStatus,
    ) : BindingObservation

    data class Bound(
        val binding: OrganizationBinding,
    ) : BindingObservation
}

/** Reports all runtime cleanup failures rather than stopping at the first failure. */
sealed interface RuntimeCloseResult {
    data object Success : RuntimeCloseResult

    data class Failure(
        val failures: List<RegistrarStopFailure>,
    ) : RuntimeCloseResult
}

/**
 * Owns one authenticated messaging runtime used by the registrar supervisor.
 *
 * Connectivity and organization binding are separate concerns. The registrar drives connection, binding
 * observation, permission refresh, heartbeats, shutdown notification, and final closure. The communicator is
 * borrowed by service callers and must not be independently closed.
 */
interface RegistrarRuntime {
    val communicator: Communicator
    val connectivity: Flow<RuntimeConnectivity>
    val currentConnectivity: RuntimeConnectivity

    suspend fun connect(): RuntimeResult<Unit>

    fun watchBinding(): Flow<RuntimeResult<BindingObservation>>

    suspend fun reconnectForBoundPermissions(): RuntimeResult<Unit>

    suspend fun queryBinding(): RuntimeResult<BindingStatus>

    suspend fun ensureRegistrationLease(): RuntimeResult<RegistrationLeaseResult>

    suspend fun sendHeartbeat(): RuntimeResult<Unit>

    suspend fun sendShutdown(): RuntimeResult<Unit>

    suspend fun close(): RuntimeCloseResult
}

sealed interface RuntimeCreateResult {
    data class Success(
        val runtime: RegistrarRuntime,
    ) : RuntimeCreateResult

    data class Failure(
        val failure: RegistrarFailure,
    ) : RuntimeCreateResult
}

enum class RuntimeSetupProgress {
    ACQUIRING_ACCESS_TOKEN,
    ACQUIRING_SENTINEL_CREDENTIALS,
    CONNECTING,
}

/** Receives ordered setup milestones before a runtime is returned to its owner. */
fun interface RuntimeSetupProgressSink {
    fun report(progress: RuntimeSetupProgress)
}

/**
 * Creates a messaging runtime from persisted identity credentials and reports setup progress.
 *
 * Creation may acquire authentication material before returning. A successful runtime becomes registrar owned;
 * failure must not leave unowned transport resources.
 */
fun interface RegistrarRuntimeFactory {
    suspend fun create(
        credentials: IdentityCredentials,
        progress: RuntimeSetupProgressSink,
    ): RuntimeCreateResult
}

/** Supplies deterministic jitter input to make retry scheduling testable. */
fun interface RetryRandom {
    fun normalizedSample(): Double
}
