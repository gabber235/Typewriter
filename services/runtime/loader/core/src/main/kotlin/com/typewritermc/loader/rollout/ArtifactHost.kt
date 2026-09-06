package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.loader.LoaderService
import com.typewritermc.loader.api.HOST_API_VERSION
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.artifact.ArtifactInboxReconciler
import com.typewritermc.loader.artifact.DigestProtectionState
import com.typewritermc.loader.artifact.FileCandidateRepository
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.artifact.RealmArtifactAddress
import com.typewritermc.loader.artifact.ReconnectingSharedArtifactAccess
import com.typewritermc.loader.artifact.StableRealmArtifactRoutes
import com.typewritermc.loader.artifact.VerifiedArtifactCache
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.CandidateIndex
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.HostId
import com.typewritermc.loader.deployment.PrimaryEngineTarget
import com.typewritermc.loader.deployment.RealmLoaderIntent
import com.typewritermc.loader.deployment.RealmTopology
import com.typewritermc.loader.deployment.ResolutionResult
import com.typewritermc.loader.deployment.resolveDeployment
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.nio.file.Path
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds

/**
 * Describes the Realm and roles assigned to a loader host.
 *
 * A Realm role requires a primary engine target and panel engine intent for deployment coordination.
 */
data class ArtifactHostAssignment(
    val realmId: RealmId,
    val roles: Set<RuntimePlacement>,
    val primaryEngine: PrimaryEngineTarget? = null,
    val intent: RealmLoaderIntent? = null,
) {
    init {
        if (RuntimePlacement.REALM in roles) {
            requireNotNull(primaryEngine) { "A Realm host assignment requires a primary engine target." }
            requireNotNull(intent) { "A Realm host assignment requires Realm loader intent." }
        }
    }
}

/**
 * Streams desired execution revisions, including explicit removal assignments.
 *
 * The artifact host owns applying changes and releasing prior assignment resources.
 */
fun interface ArtifactHostAssignmentSource {
    fun assignments(hostId: HostId): Flow<DesiredHostExecution>
}

/**
 * Coordinates registration, inbox imports, assignments, messaging, and hosted rollouts.
 *
 * Assignment and session replacement share a lifecycle mutex. Assignment changes rotate authorization; selected
 * transient registrar states retain a valid hosted session. Background jobs and assignment resources are released
 * through [stop].
 */
class ArtifactHost(
    private val hostId: HostId,
    private val workDirectory: Path,
    private val service: LoaderService,
    private val assignments: ArtifactHostAssignmentSource,
    private val scope: CoroutineScope,
) {
    private val artifactsRoot = workDirectory.resolve("artifacts")
    private val localBlobs = FileDigestBlobStore(artifactsRoot, telemetry = service.telemetry)
    private val candidates = FileCandidateRepository(artifactsRoot)
    private val inbox = ArtifactInboxReconciler(artifactsRoot, localBlobs, candidates, telemetry = service.telemetry)
    private val lifecycle = Mutex()
    private var latestSession: HostedMessagingSession? = null
    private val execution =
        HostExecutionOwner { assignment ->
            AssignmentRuntime(
                assignment,
                hostId,
                workDirectory,
                artifactsRoot,
                service.openTelemetry,
                service.telemetry,
                localBlobs,
                candidates,
                if (RuntimePlacement.REALM in assignment.roles) service.sharedArtifacts(assignment.realmId.value) else null,
                scope,
            )
        }
    private val desiredExecution = MutableStateFlow<DesiredHostExecution?>(null)
    private val executionReporter = BackendHostExecutionReporter()
    private var reconciliationJob: Job? = null
    private val pendingAuthorizationReleases = linkedSetOf<Long>()
    private var authorizedExecution: DesiredHostExecution? = null
    private var inboxJob: Job? = null
    private var assignmentJob: Job? = null
    private var sessionJob: Job? = null

    suspend fun start() {
        service.start().requireSuccess()
        inboxJob = scope.launch { inbox.run() }
        sessionJob =
            scope.launch {
                service.states.collect {
                    while (true) {
                        try {
                            lifecycle.withLock {
                                val state = service.states.value.state
                                val session =
                                    (state as? RegistrarState.Ready)?.let {
                                        HostedMessagingSession(
                                            id = it.connectionGeneration,
                                            organizationId = it.session.binding.organizationId,
                                            communicator = service.communicatorFor(it.connectionGeneration).requireSuccess(),
                                        )
                                    }
                                if (session == null && !state.invalidatesHostedMessagingSession()) return@withLock
                                latestSession = session
                                execution.replaceSession(session)
                            }
                            break
                        } catch (failure: Throwable) {
                            rethrowExceptionalThrowable(failure)
                            delay(1.seconds)
                        }
                    }
                }
            }
        assignmentJob =
            scope.launch {
                assignments.assignments(hostId).collect { desiredExecution.value = it }
            }
        reconciliationJob =
            scope.launch {
                while (true) {
                    val desired = desiredExecution.value
                    if (desired != null) {
                        try {
                            lifecycle.withLock {
                                if (execution.isApplied(desired) && pendingAuthorizationReleases.isEmpty() &&
                                    !execution.needsReport(desired, latestSession?.id)
                                ) {
                                    return@withLock
                                }
                                service.telemetry.artifactSpan(
                                    "artifact.assignment.lifecycle",
                                    "artifact-assignment-lifecycle-failed",
                                ) { span ->
                                    span?.annotate {
                                        attribute("host.id", hostId.value)
                                        attribute("host.expected_revision", desired.revision?.value ?: 0L)
                                        attribute("realm.id", desired.assignment?.realmId?.value ?: "unassigned")
                                        attribute(
                                            "host.roles",
                                            desired.assignment
                                                ?.roles
                                                ?.sortedBy(RuntimePlacement::name)
                                                ?.joinToString(",") ?: "none",
                                        )
                                    }
                                    if (!execution.isApplied(desired)) replaceExecution(desired)
                                    releasePendingAuthorization()
                                    if (desiredExecution.value == desired) {
                                        execution.report(desired, latestSession?.id) { observation ->
                                            executionReporter.report(observation, requireNotNull(latestSession))
                                        }
                                    }
                                }
                            }
                        } catch (failure: Throwable) {
                            rethrowExceptionalThrowable(failure)
                        }
                    }
                    delay(1.seconds)
                }
            }
    }

    private suspend fun replaceExecution(desired: DesiredHostExecution) {
        if (authorizedExecution != desired) {
            if (execution.hasRuntime || desired.assignment != null) {
                pendingAuthorizationReleases += service.rotateAuthorization().requireSuccess()
            }
            authorizedExecution = desired
        }
        val ready = service.states.value.state as? RegistrarState.Ready
        if (ready != null) {
            latestSession =
                HostedMessagingSession(
                    id = ready.connectionGeneration,
                    organizationId = ready.session.binding.organizationId,
                    communicator = service.communicatorFor(ready.connectionGeneration).requireSuccess(),
                )
        } else if (pendingAuthorizationReleases.isNotEmpty()) {
            error("Authorization rotation did not produce a ready session.")
        }
        execution.apply(desired, latestSession)
    }

    private suspend fun releasePendingAuthorization() {
        val iterator = pendingAuthorizationReleases.iterator()
        while (iterator.hasNext()) {
            service.releaseAuthorizationRotation(iterator.next()).requireSuccess()
            iterator.remove()
        }
    }

    suspend fun stop() {
        assignmentJob?.cancelAndJoin()
        reconciliationJob?.cancelAndJoin()
        sessionJob?.cancelAndJoin()
        lifecycle.withLock {
            execution.close()
            releasePendingAuthorization()
            latestSession = null
        }
        inboxJob?.cancelAndJoin()
        assignmentJob = null
        sessionJob = null
        reconciliationJob = null
        inboxJob = null
        service.stop().requireSuccess()
    }
}

internal fun RegistrarState.invalidatesHostedMessagingSession(): Boolean =
    this is RegistrarState.DegradedAfterReady || this is RegistrarState.Failed || this is RegistrarState.Stopped

internal class AssignmentRuntime(
    override val assignment: ArtifactHostAssignment,
    private val hostId: HostId,
    private val workDirectory: Path,
    private val artifactsRoot: Path,
    openTelemetry: OpenTelemetry,
    private val telemetry: ServiceTelemetry,
    private val localBlobs: FileDigestBlobStore,
    private val candidates: FileCandidateRepository,
    private val localShared: SharedArtifactAccess?,
    private val scope: CoroutineScope,
) : HostAssignmentRuntime {
    @Volatile
    override var status: ParticipantStatus? = null
        private set

    private val mutableMessaging = MutableStateFlow<HostedMessagingSession?>(null)
    private val sharedArtifacts = localShared ?: ReconnectingSharedArtifactAccess(assignment.realmId.value, mutableMessaging)
    private val projections = BlobProjectionRepository(sharedArtifacts)
    private val participant =
        HostRolloutParticipant(
            assignment.realmId,
            hostId,
            workDirectory,
            object : HostedRuntimeHost {
                override val messaging: StateFlow<HostedMessagingSession?> = mutableMessaging.asStateFlow()
                override val openTelemetry: OpenTelemetry = openTelemetry
                override val sharedArtifacts: SharedArtifactAccess = this@AssignmentRuntime.sharedArtifacts
            },
            projections,
            VerifiedArtifactCache(sharedArtifacts, localBlobs),
            ParticipantStatePublisher { event ->
                status = event.status
                ReconnectingParticipantStatePublisher(mutableMessaging).publish(event)
            },
            scope,
            telemetry = telemetry,
        )
    private val rolloutState =
        if (RuntimePlacement.REALM in assignment.roles) FileRolloutStateRepository(assignment.realmId, artifactsRoot) else null
    private var router: CommunicatorRouter? = null
    private var coordinator: Job? = null
    private val maintenance: Job? =
        localShared?.let {
            scope.launch {
                while (true) {
                    maintainArtifacts()
                    delay(1.hours)
                }
            }
        }

    override suspend fun replaceSession(session: HostedMessagingSession?) {
        if (mutableMessaging.value?.id == session?.id && (session != null || router == null)) return
        coordinator?.cancelAndJoin()
        coordinator = null
        router?.stop()?.requireSuccess("replace")
        router = null
        mutableMessaging.value = null
        router = session?.let { createRouter(it) }
        router?.start()?.requireSuccess("start")
        mutableMessaging.value = session
        coordinator =
            session?.takeIf { rolloutState != null }?.let { current ->
                scope.launch { coordinateDeployments(current, requireNotNull(rolloutState)) }
            }
    }

    private fun createRouter(session: HostedMessagingSession): CommunicatorRouter {
        val broadcastAddress = RealmBroadcastAddress(session.organizationId, assignment.realmId)
        val artifactAddress = RealmArtifactAddress(assignment.realmId.value, session.organizationId)
        val routes =
            communicatorRoutes {
                RolloutHostRoutes(
                    presence = { probe ->
                        if (probe.realmId != assignment.realmId) {
                            null
                        } else {
                            RealmHostPresence(
                                probe.probeId,
                                hostId,
                                ArtifactVersion(HOST_API_VERSION),
                                assignment.roles,
                                participant.activeProjection,
                            )
                        }
                    },
                    participant = participant,
                ).register(this, broadcastAddress)
                rolloutState?.let { RolloutCoordinatorRoutes(it).register(this, broadcastAddress) }
                if (RuntimePlacement.REALM in assignment.roles) {
                    StableRealmArtifactRoutes(sharedArtifacts).register(this, artifactAddress)
                }
            }
        return session.communicator.createRouter(routes, scope)
    }

    private suspend fun coordinateDeployments(
        session: HostedMessagingSession,
        state: FileRolloutStateRepository,
    ) {
        val primaryEngine = requireNotNull(assignment.primaryEngine)
        val intent = requireNotNull(assignment.intent)
        val messenger = CommunicatorRolloutMessenger(session.organizationId, session.communicator)
        while (true) {
            val topology = discoverTopology(assignment.realmId, messenger)
            if (topology == null) {
                delay(1.seconds)
                continue
            }
            val resolution =
                telemetry.artifactSpan(
                    "artifact.deployment.resolve",
                    "artifact-deployment-resolve-failed",
                ) { span ->
                    span?.annotate {
                        attribute("realm.id", assignment.realmId.value)
                        attribute("host.id", hostId.value)
                    }
                    resolveDeployment(CandidateIndex(candidates.candidates()), topology, primaryEngine, intent)
                }
            if (resolution is ResolutionResult.Resolved) {
                val digest = DeploymentContentCodec.digest(resolution.content)
                val current = state.current()
                val rollout =
                    CoordinatedRollout(
                        assignment.realmId,
                        topology,
                        resolution.manifests,
                        messenger,
                        projections,
                        state,
                        telemetry = telemetry,
                    )
                if (current?.snapshot?.contentDigest != digest) {
                    val snapshot =
                        DeploymentSnapshot(
                            DeploymentGeneration((current?.snapshot?.generation?.value ?: 0L) + 1L),
                            digest,
                            resolution.content,
                        )
                    runRollout { rollout.rollOut(snapshot) }
                } else {
                    runRollout { rollout.reconcileCommitted(current) }
                }
            }
            delay(1.seconds)
        }
    }

    private suspend fun runRollout(block: suspend () -> Unit) {
        try {
            block()
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
        }
    }

    private suspend fun discoverTopology(
        realmId: RealmId,
        messenger: RolloutMessenger,
    ): RealmTopology? {
        val probe = ProbeRealmHosts(realmId)
        val responses =
            messenger
                .discover(probe, emptySet(), 5.seconds)
                .filter { it.probeId == probe.probeId }
        return responses.toReadyTopology()
    }

    override suspend fun close() {
        maintenance?.cancelAndJoin()
        coordinator?.cancelAndJoin()
        coordinator = null
        router?.stop()?.requireSuccess("stop")
        router = null
        mutableMessaging.value = null
        participant.close()
    }

    private suspend fun maintainArtifacts() {
        telemetry.artifactSpan(
            "artifact.maintenance",
            "artifact-maintenance-failed",
        ) { span ->
            val current = rolloutState?.current()
            val previous = rolloutState?.previous()
            val shared = requireNotNull(localShared).catalog()
            val accepted = candidates.candidates()
            val projectionDigests =
                buildSet {
                    current?.projections?.values?.mapTo(this) { it.blob }
                    previous?.projections?.values?.mapTo(this) { it.blob }
                }
            val protection =
                DigestProtectionState(
                    currentDeployment = current?.snapshot,
                    previousDeployment = previous?.snapshot,
                    currentSharedArtifacts = shared.artifacts,
                    activeTransferDigests = localBlobs.activeTransferDigests(),
                    acceptedCandidateDigests = accepted.mapTo(mutableSetOf()) { it.artifact.digest },
                    rolloutProjectionDigests = projectionDigests,
                )
            val expiredTransfers = localBlobs.removeExpiredTransfers()
            val deleted = localBlobs.collectGarbage(protection.protectedDigests())
            span?.annotate {
                attribute("realm.id", assignment.realmId.value)
                attribute("host.id", hostId.value)
                attribute("maintenance.expired_transfer_count", expiredTransfers.toLong())
                attribute("maintenance.deleted_count", deleted.toLong())
            }
        }
    }
}

internal fun List<RealmHostPresence>.toReadyTopology(): RealmTopology? {
    val responsesByHost = groupBy(RealmHostPresence::hostId)
    if (responsesByHost.values.any { it.size != 1 }) return null
    val active = responsesByHost.mapValues { it.value.single() }
    val realmHosts = active.values.filter { RuntimePlacement.REALM in it.assignedRoles }
    if (realmHosts.size != 1) return null
    val primaryHosts =
        active.values
            .filter { RuntimePlacement.PRIMARY_ENGINE in it.assignedRoles }
            .mapTo(linkedSetOf(), RealmHostPresence::hostId)
    if (primaryHosts.isEmpty()) return null
    return RealmTopology(
        realmHost = realmHosts.single().hostId,
        primaryEngineHosts = primaryHosts,
        hostApis = active.mapValues { it.value.hostApi },
    )
}

private class ReconnectingParticipantStatePublisher(
    private val sessions: StateFlow<HostedMessagingSession?>,
) : ParticipantStatePublisher {
    override suspend fun publish(event: ParticipantStateChanged) {
        val session = sessions.value ?: return
        CommunicatorParticipantStatePublisher(session.organizationId, session.communicator).publish(event)
    }
}

private fun <Value> RegistrarResult<Value>.requireSuccess(): Value =
    when (this) {
        is RegistrarResult.Success -> value
        is RegistrarResult.Failure -> error("Loader service is unavailable: $failure")
    }

private fun com.typewritermc.services.libs.registrar.RegistrarStopResult.requireSuccess() {
    if (this is com.typewritermc.services.libs.registrar.RegistrarStopResult.Failure) {
        error("Loader service stop failed: $failures")
    }
}

private fun RouterResult.requireSuccess(operation: String) {
    if (this is RouterResult.Failure) error("Artifact host router $operation failed: $error")
}
