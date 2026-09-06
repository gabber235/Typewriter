package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderServiceConnection
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.HostId
import com.typewritermc.loader.deployment.PrimaryEngineTarget
import com.typewritermc.loader.deployment.RealmLoaderIntent
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.service.v1.topology.ChildRuntimeState
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.RegisterServiceHost
import skirout.service.v1.topology.RegisterServiceHostRequest
import skirout.service.v1.topology.RegisterServiceHostResponse
import skirout.service.v1.topology.ReportHostExecution
import skirout.service.v1.topology.ReportHostExecutionRequest
import skirout.service.v1.topology.ReportHostExecutionResponse
import skirout.service.v1.topology.SupportedEngine
import skirout.service.v1.topology.WatchHostExecution
import skirout.service.v1.topology.WatchHostExecutionRequest
import skirout.service.v1.topology.WatchHostExecutionResponse
import java.time.Clock
import java.time.Instant
import kotlin.time.Duration.Companion.seconds

@JvmInline
private value class HostExecutionAddress(
    val serviceId: String,
)

private val hostExecutionRequestAddress = hostExecutionAddress("cloud.to.service.{service}.execution.watch")
private val hostExecutionUpdateAddress = hostExecutionAddress("cloud.from.service.{service}.execution.watch")
private val hostRegistrationAddress = hostExecutionAddress("cloud.to.service.{service}.execution.register")
private val hostExecutionReportAddress = hostExecutionAddress("cloud.to.service.{service}.execution.report")
private val hostRegistrationClassifier =
    ResponseClassifier<RegisterServiceHostResponse> { response ->
        when (response) {
            is RegisterServiceHostResponse.SuccessWrapper -> classification(ResponseOutcome.SUCCESS, "success")
            is RegisterServiceHostResponse.InternalErrorWrapper -> classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
            else -> classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
        }
    }
private val hostRegistrationContract =
    skirUnaryContract(
        method = RegisterServiceHost,
        name = OperationName.of("host.execution.register"),
        address = hostRegistrationAddress,
        responsePolicy = ResponsePolicy(RegisterServiceHostResponse.createInternalError(), hostRegistrationClassifier),
        failureSlug = ErrorSlug.of("host-execution-register-failed"),
    )
private val hostExecutionClassifier =
    ResponseClassifier<WatchHostExecutionResponse> { response ->
        when (response) {
            is WatchHostExecutionResponse.DesiredWrapper -> classification(ResponseOutcome.SUCCESS, "desired")
            is WatchHostExecutionResponse.InternalErrorWrapper -> classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
            else -> classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
        }
    }
private val hostExecutionContract =
    skirWatchContract(
        method = WatchHostExecution,
        updateSerializer = WatchHostExecutionResponse.serializer,
        name = OperationName.of("host.execution.watch"),
        requestAddress = hostExecutionRequestAddress,
        updateAddress = hostExecutionUpdateAddress,
        initialPolicy = ResponsePolicy(WatchHostExecutionResponse.createInternalError(), hostExecutionClassifier),
        updateClassifier = hostExecutionClassifier,
        failureSlug = ErrorSlug.of("host-execution-watch-failed"),
    )
private val hostExecutionReportClassifier =
    ResponseClassifier<ReportHostExecutionResponse> { response ->
        when (response) {
            is ReportHostExecutionResponse.SuccessWrapper -> classification(ResponseOutcome.SUCCESS, "success")
            is ReportHostExecutionResponse.StaleRevisionErrorWrapper -> classification(ResponseOutcome.DOMAIN_ERROR, "stale-revision")
            is ReportHostExecutionResponse.InternalErrorWrapper -> classification(ResponseOutcome.INTERNAL_ERROR, "internal-error")
            else -> classification(ResponseOutcome.DOMAIN_ERROR, "unknown")
        }
    }
private val hostExecutionReportContract =
    skirUnaryContract(
        method = ReportHostExecution,
        name = OperationName.of("host.execution.report"),
        address = hostExecutionReportAddress,
        responsePolicy = ResponsePolicy(ReportHostExecutionResponse.createInternalError(), hostExecutionReportClassifier),
        failureSlug = ErrorSlug.of("host-execution-report-failed"),
    )

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
    override fun assignments(hostId: HostId): Flow<ArtifactHostAssignment?> =
        service.states
            .flatMapLatest { snapshot ->
                val ready = snapshot.state as? RegistrarState.Ready ?: return@flatMapLatest emptyFlow()
                val communicator =
                    when (val result = service.communicatorFor(ready.connectionGeneration)) {
                        is RegistrarResult.Success -> result.value
                        is RegistrarResult.Failure -> return@flatMapLatest emptyFlow()
                    }
                flow {
                    val address = HostExecutionAddress(ready.session.identity.serviceId)
                    while (true) {
                        val registration = communicator.request(hostRegistrationContract, address, registrationRequest())
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
                                hostExecutionContract,
                                address,
                                WatchHostExecutionRequest(),
                            ).collect { result ->
                                val message = (result as? CommunicationResult.Success)?.value ?: return@collect
                                val response =
                                    when (message) {
                                        is WatchMessage.Initial -> message.value
                                        is WatchMessage.Update -> message.value
                                    }
                                emit(response.toArtifactHostAssignment(panelEngine, address.serviceId))
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

internal fun WatchHostExecutionResponse.toArtifactHostAssignment(
    panelEngine: ArtifactRequirement,
    serviceId: String? = null,
): ArtifactHostAssignment? {
    val desired = (this as? WatchHostExecutionResponse.DesiredWrapper)?.value ?: return null
    val realm = desired.realm
    val engine = desired.engine
    val realmId = realm?.realmId?.stringKey() ?: engine?.realm?.realmId?.stringKey() ?: return null
    val roles =
        buildSet {
            if (realm != null) {
                add(RuntimePlacement.REALM)
                add(RuntimePlacement.PANEL_ENGINE)
            }
            if (engine != null) add(RuntimePlacement.PRIMARY_ENGINE)
        }
    return ArtifactHostAssignment(
        realmId = RealmId(realmId),
        roles = roles,
        primaryEngine =
            realm?.targetEngine?.let { target ->
                PrimaryEngineTarget(
                    ArtifactId(target.engineId),
                    VersionConstraint(target.versionConstraint),
                )
            },
        intent = realm?.let { RealmLoaderIntent(panelEngine) },
        topologyRevision = desired.topologyRevision,
        serviceId = serviceId,
    )
}

/**
 * Reports participant lifecycle state to the backend at the assigned topology revision.
 *
 * Reports are serialized and retain role state for refresh. Revision checking lets the backend reject observations
 * from superseded assignments.
 */
internal class BackendHostExecutionReporter(
    private val topologyRevision: Long,
    private val serviceId: String,
    private val roles: Set<RuntimePlacement>,
    private val sessions: StateFlow<com.typewritermc.loader.api.HostedMessagingSession?>,
    private val clock: Clock = Clock.systemUTC(),
) {
    private val reports = Mutex()
    private var lastReport =
        ExecutionReport(
            realmState = absentState().takeIf { RuntimePlacement.REALM in roles },
            engineState = absentState().takeIf { RuntimePlacement.PRIMARY_ENGINE in roles },
        )

    suspend fun reportCurrent() {
        reports.withLock {
            val now = clock.instant()
            lastReport =
                lastReport.copy(
                    realmState = lastReport.realmState?.copy(updatedAt = now),
                    engineState = lastReport.engineState?.copy(updatedAt = now),
                )
            submit(lastReport)
        }
    }

    suspend fun report(status: ParticipantStatus) {
        reports.withLock {
            val now = clock.instant()
            lastReport =
                ExecutionReport(
                    realmState = status.toChildRuntimeState(now, RuntimePlacement.REALM).takeIf { RuntimePlacement.REALM in roles },
                    engineState =
                        status
                            .toChildRuntimeState(now, RuntimePlacement.PRIMARY_ENGINE)
                            .takeIf { RuntimePlacement.PRIMARY_ENGINE in roles },
                )
            submit(lastReport)
        }
    }

    private fun absentState() =
        ChildRuntimeState(
            status = ChildRuntimeStatus.ABSENT,
            activeArtifactVersion = null,
            message = null,
            updatedAt = clock.instant(),
        )

    private suspend fun submit(report: ExecutionReport) {
        val session = sessions.value ?: return
        val request =
            ReportHostExecutionRequest(
                topologyRevision = topologyRevision,
                realmState = report.realmState,
                engineState = report.engineState,
            )
        when (val result = session.communicator.request(hostExecutionReportContract, HostExecutionAddress(serviceId), request)) {
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

    private data class ExecutionReport(
        val realmState: ChildRuntimeState?,
        val engineState: ChildRuntimeState?,
    )
}

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

private fun hostExecutionAddress(pattern: String): AddressTemplate<HostExecutionAddress> =
    addressTemplate(
        pattern,
        { addressValuesOf("service" to it.serviceId) },
        { HostExecutionAddress(it.require("service")) },
    )

private fun classification(
    outcome: ResponseOutcome,
    variant: String,
) = ResponseClassification(outcome, ResponseVariant.of(variant))
