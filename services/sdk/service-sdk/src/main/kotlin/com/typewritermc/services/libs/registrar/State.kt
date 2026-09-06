package com.typewritermc.services.libs.registrar

/**
 * Describes registration progress, readiness, degradation, and terminal outcomes.
 *
 * Ready includes a connection generation for safe communicator borrowing. DegradedAfterReady retains the last
 * session context but does not itself promise transport usability. IdentityOutcomeUnknown distinguishes ambiguous
 * issuance from a retryable failure.
 */
sealed interface RegistrarState {
    data object Idle : RegistrarState

    data object LoadingIdentity : RegistrarState

    data object IssuingIdentity : RegistrarState

    data class PersistingIdentity(
        val identity: ServiceIdentity,
    ) : RegistrarState

    data class AcquiringAccessToken(
        val identity: ServiceIdentity,
    ) : RegistrarState

    data object AcquiringSentinelCredentials : RegistrarState

    data class Connecting(
        val attempt: Long,
    ) : RegistrarState

    data class AwaitingBinding(
        val identity: ServiceIdentity,
        val registrationToken: RegistrationToken?,
    ) : RegistrarState

    data class Reauthorizing(
        val binding: OrganizationBinding,
    ) : RegistrarState

    data class Ready(
        val session: ReadySession,
        val connectionGeneration: Long,
    ) : RegistrarState

    data class DegradedBeforeReady(
        val stage: RegistrarStage,
        val failure: RegistrarFailure,
        val retry: RetrySchedule,
    ) : RegistrarState

    data class DegradedAfterReady(
        val session: ReadySession,
        val stage: RegistrarStage,
        val failure: RegistrarFailure,
        val retry: RetrySchedule,
    ) : RegistrarState

    data class Failed(
        val failure: RegistrarFailure,
    ) : RegistrarState

    data class IdentityOutcomeUnknown(
        val failure: RegistrarFailure.IdentityIssuance,
    ) : RegistrarState

    data object Stopping : RegistrarState

    data class Stopped(
        val result: RegistrarStopResult,
    ) : RegistrarState
}

/**
 * Orders observable state transitions and relates them to a registrar attempt.
 *
 * Sequence distinguishes observations within an attempt. StateFlow consumers see current state and may skip
 * intermediate transitions when collecting slowly.
 */
data class RegistrarSnapshot(
    val sequence: Long,
    val attempt: Long,
    val state: RegistrarState,
)
