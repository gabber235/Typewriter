package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.client.Communicator
import kotlinx.coroutines.flow.Flow
import kotlin.time.Duration

/** Result of an expected registrar operation. */
sealed interface RegistrarResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : RegistrarResult<Value>

    data class Failure(
        val failure: RegistrarFailure,
    ) : RegistrarResult<Nothing>
}

/** Safe, typed registrar failure. */
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

enum class AccessTokenFailureReason { UNAVAILABLE, REJECTED, PROTOCOL }

enum class SentinelFailureReason { UNAVAILABLE, REJECTED, PROTOCOL, STALE }

enum class MessagingOperation {
    RUNTIME_CREATE,
    CONNECT,
    BINDING_WATCH,
    BINDING_QUERY,
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

sealed interface CredentialLoadResult {
    data object Missing : CredentialLoadResult

    data class Loaded(
        val credentials: IdentityCredentials,
    ) : CredentialLoadResult

    data class Failure(
        val error: CredentialStorageError,
    ) : CredentialLoadResult
}

sealed interface CredentialStoreResult {
    data object Success : CredentialStoreResult

    data class Failure(
        val error: CredentialStorageError,
    ) : CredentialStoreResult
}

interface CredentialStorage {
    suspend fun load(): CredentialLoadResult

    suspend fun store(credentials: IdentityCredentials): CredentialStoreResult
}

enum class IdentityRejectionReason {
    MALFORMED_REQUEST,
    UNKNOWN_ROLE,
    ROLES_REQUIRED,
    ROLE_UNKNOWN_PROPERTY,
    ROLE_TYPE_INVALID,
    ROLE_VERSION_BLANK,
    ROLE_INVALID,
    CUSTOM_ROLE_NAME_REQUIRED,
    CUSTOM_ROLE_NAME_INVALID,
    BUILTIN_ROLE_NAME_FORBIDDEN,
    ENGINE_ROLE_DUPLICATE,
    REALM_ROLE_DUPLICATE,
    CUSTOM_ROLE_DUPLICATE,
}

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

fun interface IdentityIssuer {
    suspend fun issue(roles: List<ServiceRole>): IdentityIssueResult
}

enum class RuntimeConnectivity { DISCONNECTED, CONNECTING, CONNECTED }

sealed interface RuntimeResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : RuntimeResult<Value>

    data class Failure(
        val failure: RegistrarFailure,
    ) : RuntimeResult<Nothing>
}

sealed interface BindingStatus {
    data class Unbound(
        val token: RegistrationToken?,
    ) : BindingStatus

    data class Bound(
        val binding: OrganizationBinding,
    ) : BindingStatus
}

sealed interface BindingObservation {
    data class Initial(
        val status: BindingStatus,
    ) : BindingObservation

    data class Bound(
        val binding: OrganizationBinding,
    ) : BindingObservation
}

sealed interface RuntimeCloseResult {
    data object Success : RuntimeCloseResult

    data class Failure(
        val failures: List<RegistrarStopFailure>,
    ) : RuntimeCloseResult
}

interface RegistrarRuntime {
    val communicator: Communicator
    val connectivity: Flow<RuntimeConnectivity>
    val currentConnectivity: RuntimeConnectivity

    suspend fun connect(): RuntimeResult<Unit>

    fun watchBinding(): Flow<RuntimeResult<BindingObservation>>

    suspend fun reconnectForBoundPermissions(): RuntimeResult<Unit>

    suspend fun queryBinding(): RuntimeResult<BindingStatus>

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

fun interface RuntimeSetupProgressSink {
    fun report(progress: RuntimeSetupProgress)
}

fun interface RegistrarRuntimeFactory {
    suspend fun create(
        credentials: IdentityCredentials,
        progress: RuntimeSetupProgressSink,
    ): RuntimeCreateResult
}

fun interface RetryRandom {
    fun normalizedSample(): Double
}

fun interface RegistrarDelay {
    suspend fun delay(duration: Duration)
}
