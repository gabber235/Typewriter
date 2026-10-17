package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderServiceConnection
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.PrimaryEngineTarget
import com.typewritermc.loader.deployment.RealmLoaderIntent
import com.typewritermc.protocol.transport.generated.ServiceRouteScope
import com.typewritermc.protocol.transport.generated.hostExecutionReport
import com.typewritermc.protocol.transport.generated.hostExecutionWatch
import com.typewritermc.protocol.transport.generated.serviceHostRegister
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
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

private val hostRegistrationClassifier =
    ResponseClassifier<RegisterServiceHostResponse> { response ->
        when (response) {
            is RegisterServiceHostResponse.SuccessWrapper -> classification(ResponseOutcome.SUCCESS, "success")
            is RegisterServiceHostResponse.InternalErrorWrapper -> classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
            else -> classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
        }
    }
internal val hostRegistrationResponsePolicy =
    ResponsePolicy(RegisterServiceHostResponse.createInternalError(), hostRegistrationClassifier)
internal val hostExecutionResponseClassifier =
    ResponseClassifier<WatchHostExecutionResponse> { response ->
        when (response) {
            is WatchHostExecutionResponse.DesiredWrapper -> classification(ResponseOutcome.SUCCESS, "desired")
            is WatchHostExecutionResponse.InternalErrorWrapper -> classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
            else -> classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
        }
    }
internal val hostExecutionResponsePolicy =
    ResponsePolicy(WatchHostExecutionResponse.createInternalError(), hostExecutionResponseClassifier)
private val hostExecutionReportClassifier =
    ResponseClassifier<ReportHostExecutionResponse> { response ->
        when (response) {
            is ReportHostExecutionResponse.SuccessWrapper -> classification(ResponseOutcome.SUCCESS, "success")
            is ReportHostExecutionResponse.StaleRevisionErrorWrapper -> classification(ResponseOutcome.DOMAIN_ERROR, "stale-revision")
            is ReportHostExecutionResponse.InternalErrorWrapper -> classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
            else -> classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
        }
    }
internal val hostExecutionReportResponsePolicy =
    ResponsePolicy(ReportHostExecutionResponse.createInternalError(), hostExecutionReportClassifier)

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
                    val registrationContract = address.serviceHostRegister(hostRegistrationResponsePolicy)
                    val executionContract =
                        address.hostExecutionWatch(hostExecutionResponsePolicy, hostExecutionResponseClassifier)
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
                    scope.hostExecutionReport(hostExecutionReportResponsePolicy),
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
    val status =
        when (this) {
            is ParticipantStatus.Idle -> {
                ChildRuntimeStatus.ABSENT
            }

            is ParticipantStatus.Staging, is ParticipantStatus.Staged -> {
                ChildRuntimeStatus.STAGING
            }

            is ParticipantStatus.Committing -> {
                ChildRuntimeStatus.STAGING
            }

            is ParticipantStatus.Active -> {
                when (current.health) {
                    RuntimeHealthSnapshot.Healthy -> ChildRuntimeStatus.ACTIVE
                    RuntimeHealthSnapshot.Staged -> ChildRuntimeStatus.STAGING
                    is RuntimeHealthSnapshot.Unhealthy -> ChildRuntimeStatus.FAILED
                }
            }

            is ParticipantStatus.Aborting -> {
                ChildRuntimeStatus.QUIESCING
            }

            is ParticipantStatus.RollingBack -> {
                ChildRuntimeStatus.QUIESCING
            }

            is ParticipantStatus.Failed -> {
                ChildRuntimeStatus.FAILED
            }
        }
    val message =
        when (this) {
            is ParticipantStatus.Active -> (current.health as? RuntimeHealthSnapshot.Unhealthy)?.reasons?.joinToString("; ")
            is ParticipantStatus.Failed -> reason
            else -> null
        }
    val activeArtifactVersion = projectionReference()?.runtimeVersions?.get(placement)?.value
    return ChildRuntimeState(status = status, activeArtifactVersion = activeArtifactVersion, message = message, updatedAt = now)
}

private fun ParticipantStatus.projectionReference(): ProjectionReference? =
    when (this) {
        is ParticipantStatus.Idle -> {
            null
        }

        is ParticipantStatus.Staging -> {
            candidate
        }

        is ParticipantStatus.Staged -> {
            candidate
        }

        is ParticipantStatus.Committing -> {
            candidate
        }

        is ParticipantStatus.Active -> {
            current.projection
        }

        is ParticipantStatus.Aborting -> {
            candidate
        }

        is ParticipantStatus.RollingBack -> {
            failed
        }

        is ParticipantStatus.Failed -> {
            when (val state = recoverable) {
                RecoverableParticipantState.Empty -> null
                is RecoverableParticipantState.Active -> state.current.projection
                is RecoverableParticipantState.Staged -> state.candidate
            }
        }
    }

private fun RecordId.stringKey(): String =
    when (val value = key) {
        is RecordIdKey.StringWrapper -> value.value
        else -> error("Topology record ids must use string keys.")
    }

private fun classification(
    outcome: ResponseOutcome,
    variant: String,
) = ResponseClassification(outcome, ResponseVariant.of(variant))
