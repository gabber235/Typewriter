package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderServiceConnection
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.PrimaryEngineTarget
import com.typewritermc.loader.deployment.RealmLoaderIntent
import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.protocol.transport.generated.hostExecutionReport
import com.typewritermc.protocol.transport.generated.hostExecutionWatch
import com.typewritermc.protocol.transport.generated.serviceHostRegister
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.RecoverableParticipantState
import skirout.service.v1.topology.ChildRuntimeState
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.RegisterServiceHostRequest
import skirout.service.v1.topology.RegisterServiceHostResponse
import skirout.service.v1.topology.ReportHostExecutionRequest
import skirout.service.v1.topology.ReportHostExecutionResponse
import skirout.service.v1.topology.SupportedEngine
import skirout.service.v1.topology.WatchHostExecutionRequest
import skirout.service.v1.topology.WatchHostExecutionResponse
import java.time.Clock
import java.time.Instant
import kotlin.time.Duration.Companion.seconds

/**
 * Registers host capabilities and watches backend execution assignments through ready messaging generations.
 *
 * Session changes replace the watch and repeated assignments are suppressed. Realm assignment also supplies a
 * panel engine role. Losing readiness alone does not emit a removal assignment.
 */
class BackendArtifactHostAssignmentSource(
    private val service: LoaderServiceConnection,
    private val panelEngine: ArtifactRequirement,
    private val entrypoint: HostEntrypoint,
) : ArtifactHostAssignmentSource {
    @OptIn(ExperimentalCoroutinesApi::class)
    override fun assignments(): Flow<DesiredHostExecution> =
        service.states
            .flatMapLatest { snapshot ->
                val ready = snapshot.state as? RegistrarState.Ready ?: return@flatMapLatest emptyFlow()
                val communicator =
                    when (val result = service.communicatorFor(ready.connectionGeneration)) {
                        is RegistrarResult.Success -> result.value
                        is RegistrarResult.Failure -> return@flatMapLatest emptyFlow()
                    }
                flow {
                    val address = ServiceRouteScope(ready.session.identity.serviceId.value)
                    val registrationContract = address.serviceHostRegister
                    val executionContract = address.hostExecutionWatch
                    while (true) {
                        val registration = communicator.request(registrationContract, address, registrationRequest())
                        val registered =
                            (
                                (registration as? CommunicationResult.Success)?.value
                                    is RegisterServiceHostResponse.SuccessWrapper
                            )
                        if (!registered) {
                            delay(1.seconds)
                            continue
                        }
                        communicator
                            .watch(
                                executionContract,
                                address,
                                WatchHostExecutionRequest(),
                            ).collect { result ->
                                val message = (result as? CommunicationResult.Success)?.value ?: return@collect
                                val response =
                                    when (message) {
                                        is WatchMessage.Initial -> message.value
                                        is WatchMessage.Update -> message.value
                                    }
                                response
                                    .toDesiredHostExecution(panelEngine, ready.session.identity.serviceId)
                                    ?.let { emit(it) }
                            }
                        delay(1.seconds)
                    }
                }
            }.distinctUntilChanged()

    private fun registrationRequest(): RegisterServiceHostRequest =
        RegisterServiceHostRequest(
            entrypoint = entrypoint.name,
            canHostRealm = true,
            supportedEngines =
                when (entrypoint) {
                    HostEntrypoint.PAPER -> listOf(SupportedEngine(engineId = "typewritermc:paper"))
                    HostEntrypoint.STANDALONE -> emptyList()
                },
        )
}

/** Converts the backend topology projection into a host intent, preserving an empty desired assignment. */
internal fun WatchHostExecutionResponse.toDesiredHostExecution(
    panelEngine: ArtifactRequirement,
    serviceId: ServiceId,
): DesiredHostExecution? {
    val desired = (this as? WatchHostExecutionResponse.DesiredWrapper)?.value ?: return null
    val realm = desired.realm
    val engine = desired.engine
    val realmId = realm?.realmId?.stringKey() ?: engine?.realm?.realmId?.stringKey()
    val assignment =
        realmId?.let {
            ArtifactHostAssignment(
                realmId = RealmId(it),
                roles =
                    buildSet {
                        if (realm != null) {
                            add(RuntimePlacement.REALM)
                            add(RuntimePlacement.PANEL_ENGINE)
                        }
                        if (engine != null) add(RuntimePlacement.PRIMARY_ENGINE)
                    },
                primaryEngine =
                    realm?.targetEngine?.let { target ->
                        PrimaryEngineTarget(ArtifactId(target.engineId), VersionConstraint(target.versionConstraint))
                    },
                intent = realm?.let { RealmLoaderIntent(panelEngine) },
            )
        }
    return DesiredHostExecution(ExecutionRevision(serviceId, desired.topologyRevision), assignment)
}

/** Reports completed local execution transitions and tolerates stale backend revisions. */
internal class BackendHostExecutionReporter(
    private val clock: Clock = Clock.systemUTC(),
) {
    /** Sends a host observation after local lifecycle completion, including an empty assignment. */
    suspend fun report(
        observation: HostExecutionObservation,
        session: com.typewritermc.loader.api.HostedMessagingSession,
    ) {
        val now = clock.instant()

        fun state(placement: RuntimePlacement): ChildRuntimeState? {
            if (placement !in observation.roles) return null
            return observation.status?.toChildRuntimeState(now, placement)
                ?: ChildRuntimeState(status = ChildRuntimeStatus.ABSENT, activeArtifactVersion = null, message = null, updatedAt = now)
        }
        val request =
            ReportHostExecutionRequest(
                topologyRevision = observation.revision.value,
                realmState = state(RuntimePlacement.REALM),
                engineState = state(RuntimePlacement.PRIMARY_ENGINE),
            )
        val scope = ServiceRouteScope(observation.revision.serviceId.value)
        when (
            val result =
                session.communicator.request(
                    scope.hostExecutionReport,
                    scope,
                    request,
                )
        ) {
            is CommunicationResult.Failure -> {
                error("Host execution report failed: ${result.error}")
            }

            is CommunicationResult.Success -> {
                when (result.value) {
                    is ReportHostExecutionResponse.SuccessWrapper,
                    is ReportHostExecutionResponse.StaleRevisionErrorWrapper,
                    -> Unit

                    is ReportHostExecutionResponse.InternalErrorWrapper -> error("Host execution report failed internally.")

                    else -> error("Host execution report returned an unknown response.")
                }
            }
        }
    }
}

/** Maps loader lifecycle and health state to the backend topology status contract. */
internal fun ParticipantStatus.toChildRuntimeState(
    now: Instant,
    placement: RuntimePlacement,
): ChildRuntimeState {
    val phase = phase
    val status =
        when (phase) {
            is ParticipantPhase.StagingWrapper, is ParticipantPhase.StagedWrapper, is ParticipantPhase.CommittingWrapper -> {
                ChildRuntimeStatus.STAGING
            }

            is ParticipantPhase.ActiveWrapper -> {
                when (phase.value.current.health) {
                    ProjectionHealth.HEALTHY -> ChildRuntimeStatus.ACTIVE
                    ProjectionHealth.STAGED -> ChildRuntimeStatus.STAGING
                    else -> ChildRuntimeStatus.FAILED
                }
            }

            is ParticipantPhase.AbortingWrapper, is ParticipantPhase.RollingBackWrapper -> {
                ChildRuntimeStatus.QUIESCING
            }

            is ParticipantPhase.FailedWrapper -> {
                ChildRuntimeStatus.FAILED
            }

            else -> {
                ChildRuntimeStatus.ABSENT
            }
        }
    val message =
        when (phase) {
            is ParticipantPhase.ActiveWrapper -> {
                (phase.value.current.health as? ProjectionHealth.UnhealthyWrapper)?.value?.reasons?.joinToString("; ")
            }

            is ParticipantPhase.FailedWrapper -> {
                phase.value.reason
            }

            else -> {
                null
            }
        }
    return ChildRuntimeState(
        status = status,
        activeArtifactVersion = phase.projectionReference()?.runtimeVersion(placement),
        message = message,
        updatedAt = now,
    )
}

private fun ParticipantPhase.projectionReference(): ProjectionReference? =
    when (this) {
        is ParticipantPhase.StagingWrapper -> {
            value.candidate
        }

        is ParticipantPhase.StagedWrapper -> {
            value.candidate
        }

        is ParticipantPhase.CommittingWrapper -> {
            value.candidate
        }

        is ParticipantPhase.ActiveWrapper -> {
            value.current.projection
        }

        is ParticipantPhase.AbortingWrapper -> {
            value.candidate
        }

        is ParticipantPhase.RollingBackWrapper -> {
            value.failed
        }

        is ParticipantPhase.FailedWrapper -> {
            when (val state = value.recoverable) {
                is RecoverableParticipantState.ActiveWrapper -> state.value.current.projection
                is RecoverableParticipantState.StagedWrapper -> state.value.candidate
                else -> null
            }
        }

        else -> {
            null
        }
    }

private fun RecordId.stringKey(): String =
    when (val value = key) {
        is RecordIdKey.StringWrapper -> value.value
        else -> error("Topology record ids must use string keys.")
    }
