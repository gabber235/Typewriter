package com.typewritermc.services.libs.registrar

/** Observable registrar lifecycle state. */
sealed interface RegistrarState {
    data object Idle : RegistrarState
    data object LoadingIdentity : RegistrarState
    data object IssuingIdentity : RegistrarState
    data class PersistingIdentity(val identity: ServiceIdentity) : RegistrarState
    data class AcquiringAccessToken(val identity: ServiceIdentity) : RegistrarState
    data object AcquiringSentinelCredentials : RegistrarState
    data class Connecting(val attempt: Long) : RegistrarState
    data class AwaitingBinding(
        val identity: ServiceIdentity,
        val registrationToken: RegistrationToken?,
    ) : RegistrarState
    data class Reauthorizing(val binding: OrganizationBinding) : RegistrarState
    data class Ready(
        val session: ReadySession,
        val connectionGeneration: Long,
    ) : RegistrarState
    data class Degraded(
        val session: ReadySession?,
        val stage: RegistrarStage,
        val failure: RegistrarFailure,
        val retry: RetrySchedule,
    ) : RegistrarState
    data class Failed(
        val failure: RegistrarFailure,
        val identityOutcomeMayBeAmbiguous: Boolean,
    ) : RegistrarState
    data object Stopping : RegistrarState
    data class Stopped(val result: RegistrarStopResult) : RegistrarState
}

data class RegistrarSnapshot(
    val sequence: Long,
    val attempt: Long,
    val state: RegistrarState,
)
