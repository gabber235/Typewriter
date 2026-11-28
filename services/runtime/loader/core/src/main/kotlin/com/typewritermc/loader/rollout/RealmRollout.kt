package com.typewritermc.loader.rollout

import com.typewritermc.failures.rethrowExceptional
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.HostedArtifactManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifact.toApi
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.ResolutionResult
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.protocol.transport.generated.TRANSPORT_LIMITS
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SpanPresentation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import skirout.service.v1.rollout.ActiveParticipant
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantProjection
import skirout.service.v1.rollout.ParticipantRollback
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.QueryParticipantStatusRequest
import skirout.service.v1.rollout.RealmHostPresence
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import skirout.service.v1.rollout.StagedCandidate
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Who belongs to the Realm right now: the hosts its rollout converges. A host that is not listed has left, crashed or
 * stopped answering; nothing waits for it, and it is converged again once it is listed.
 */
fun interface RealmMembership {
    suspend fun members(): List<RealmHostPresence>
}

/**
 * Sends lifecycle commands to the hosts of one Realm and reads their phase. Timeouts can produce incomplete replies;
 * the rollout reads a missing reply as no observation.
 */
interface RolloutMessenger {
    suspend fun command(
        request: ApplyRolloutCommandRequest,
        timeout: Duration,
    ): List<ApplyRolloutCommandResponse>

    suspend fun statuses(
        request: QueryParticipantStatusRequest,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): Map<ServiceId, ParticipantStatus>
}

/** Publishes immutable canonical host projections and returns exact references for participant retrieval. */
interface ProjectionRepository {
    suspend fun publish(projection: HostDeploymentProjection): ProjectionReference
}

/**
 * Persists attempt ordering and committed deployments.
 *
 * Attempt ordinals must survive restart to distinguish stale commands.
 */
interface RolloutStateRepository {
    suspend fun nextAttempt(generation: DeploymentGeneration): RolloutAttempt

    suspend fun committed(): CommittedDeployment?

    /** Makes [deployment] the committed one; the committed one before it becomes the previous one. */
    suspend fun commit(deployment: CommittedDeployment)

    /** Adds host projections of the committed deployment, such as a host that joined after the commit. */
    suspend fun recordProjections(projections: Map<ServiceId, ArtifactDigest>)
}

/** The artifact content a Realm can deploy, read from the Realm host's accepted candidates. */
interface DeploymentContents {
    /** The newest content every host of [selection] can run, or null when the accepted candidates form none. */
    suspend fun newest(selection: RealmDeploymentSelection): ResolutionResult.Resolved?

    /** The manifests of every artifact of [content], or null when one of them is no longer accepted. */
    suspend fun manifests(content: DeploymentContent): Map<ArtifactId, ImprintManifest>?
}

/**
 * How a Realm rollout paces itself. A pass runs every [pass]; status requests wait at most [request] and a command at
 * most [command], the longest a host may take to reply. A member has [memberDeadline] from joining a target to run its
 * projection healthy for [healthy] without a gap.
 */
data class RolloutTimings(
    val pass: Duration = 1.seconds,
    val request: Duration = 5.seconds,
    val command: Duration = TRANSPORT_LIMITS.replyTtl,
    val memberDeadline: Duration = 5.minutes,
    val healthy: Duration = 30.seconds,
)

/**
 * Keeps the hosts of one Realm on the Realm's target deployment.
 *
 * The target is the committed deployment, or a candidate while one is proved. Every pass reads the members from
 * [membership] and converges each member on its own toward its projection of the target, so a host that joins or
 * comes back is staged at once and a host that leaves holds nothing up. Joining, repairing and rolling back are the
 * same convergence: a member that keeps the target projection as its retained one is rolled back to it, any other is
 * staged and committed, and a staged projection the target no longer wants is aborted.
 *
 * A candidate commits once every current member has run it healthy for [RolloutTimings.healthy] without a gap; a
 * member that leaves stops counting and the others keep their proof, while a member that joins runs the candidate and
 * proves it too. No member commits a candidate before every current member staged it, so a candidate that a host
 * cannot stage is aborted without switching any running host. A member that refuses a command, or does not prove its
 * projection within [RolloutTimings.memberDeadline] of joining, fails the candidate: the target returns to the
 * committed deployment and the members still present converge back to it. Leaving is not evidence against a candidate.
 * Once every present member is back (or failed to get back), content that is still the newest is tried again.
 *
 * A member of the committed target that refuses a command, never proves its projection within the deadline, or reports
 * the projection it proved unhealthy is staged again.
 * Commands to different members run concurrently and one member never waits for another's command. Pass failures are
 * recorded and the next pass starts over from fresh observations.
 */
class RealmRollout(
    private val realmId: RealmId,
    private val membership: RealmMembership,
    private val messenger: RolloutMessenger,
    private val contents: DeploymentContents,
    private val projections: ProjectionRepository,
    private val state: RolloutStateRepository,
    private val timings: RolloutTimings = RolloutTimings(),
    private val telemetry: ServiceTelemetry? = null,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private var target: RealmTarget? = null
    private var commitOpen = false
    private val members = mutableMapOf<ServiceId, Member>()
    private val renewed = mutableSetOf<ServiceId>()

    /** Runs passes until cancelled; in flight commands belong to the caller's scope and end with it. */
    suspend fun run(): Nothing = coroutineScope { passes(this) }

    private suspend fun passes(commands: CoroutineScope): Nothing {
        while (true) {
            try {
                pass(commands)
            } catch (failure: Throwable) {
                failure.rethrowExceptional()
                telemetry.artifactSpan("artifact.rollout.pass", "artifact-rollout-pass-failed") { span ->
                    span?.recordDegraded(ErrorSlug.of("artifact-rollout-pass-failed"), failure)
                }
            }
            delay(timings.pass)
        }
    }

    private suspend fun pass(commands: CoroutineScope) {
        val presences = membership.members()
        val selection = presences.deploymentSelectionOrNull()
        val target = selection?.let { targetFor(it) }
        if (selection == null || target == null) return forgetAllBut(emptySet())
        val eligible = admit(presences, selection, target)
        val statuses = messenger.statuses(QueryParticipantStatusRequest(attempt = target.attempt), eligible, timings.request)
        eligible.forEach { host -> members.getValue(host).observe(statuses[host]) }
        val settled =
            when (target) {
                is RealmTarget.Candidate -> {
                    decide(target, selection, eligible, statuses)
                }

                is RealmTarget.Committed -> {
                    maintain(target, eligible)
                    false
                }
            }
        if (settled) return
        eligible.forEach { host -> members[host]?.let { converge(commands, target, host, it, statuses[host]) } }
    }

    /**
     * The members of [target] this pass: present hosts with a selected role whose host API runs the target. Members
     * that are gone are forgotten and hosts that arrived join.
     */
    private suspend fun admit(
        presences: List<RealmHostPresence>,
        selection: RealmDeploymentSelection,
        target: RealmTarget,
    ): Set<ServiceId> {
        val eligible =
            presences
                .filter { ServiceId(it.serviceId) in selection.selectedServices() && target.runsOn(it) }
                .map { ServiceId(it.serviceId) }
                .toSet()
        forgetAllBut(eligible)
        eligible.forEach { host -> if (host !in members) members[host] = join(target, selection, host) }
        return eligible
    }

    /** Commits or reverts [candidate] when its members decide it, and reports whether it did. */
    private suspend fun decide(
        candidate: RealmTarget.Candidate,
        selection: RealmDeploymentSelection,
        eligible: Set<ServiceId>,
        statuses: Map<ServiceId, ParticipantStatus>,
    ): Boolean {
        val failures =
            eligible.mapNotNull { host ->
                val member = members.getValue(host)
                (member.failure ?: member.overdueReason())?.let { "${host.value}: $it" }
            }
        if (failures.isNotEmpty()) {
            revert(candidate, failures)
            return true
        }
        if (!commitOpen) commitOpen = eligible.all { members.getValue(it).holds(statuses[it]) }
        if (selection.realmService !in eligible || !eligible.all { members.getValue(it).proven }) return false
        commit(candidate, eligible)
        return true
    }

    /** Ends a revert once its members are back, starts a new try for every stuck member and records joined ones. */
    private suspend fun maintain(
        committed: RealmTarget.Committed,
        eligible: Set<ServiceId>,
    ) {
        val stuck = eligible.filter { members.getValue(it).stuck }.toSet()
        if (committed.reverting && eligible.all { it in stuck || members.getValue(it).runsDesired }) {
            target = committed.copy(reverting = false)
        }
        stuck.forEach { host ->
            members.remove(host)?.command?.cancel()
            renewed += host
        }
        recordJoined(committed, eligible)
    }

    /** The target for this pass: the running candidate, a new one for newer content, or the committed deployment. */
    private suspend fun targetFor(selection: RealmDeploymentSelection): RealmTarget? {
        val current = target
        if (current is RealmTarget.Candidate || (current is RealmTarget.Committed && current.reverting)) return current
        val committed = state.committed()
        val newest = contents.newest(selection)
        val newestDigest = newest?.let { DeploymentContentCodec.digest(it.content) }
        if (newest != null && newestDigest != committed?.snapshot?.contentDigest) {
            return startCandidate(newest, requireNotNull(newestDigest), committed)
        }
        if (current is RealmTarget.Committed && current.deployment?.snapshot == committed?.snapshot) return current
        if (committed == null) return null
        val manifests =
            if (newestDigest == committed.snapshot.contentDigest) {
                requireNotNull(newest).manifests
            } else {
                contents.manifests(committed.snapshot.content) ?: return null
            }
        return replaceTarget(
            RealmTarget.Committed(
                TargetDeployment(committed.snapshot, manifests),
                committed.snapshot.generation,
                state.nextAttempt(committed.snapshot.generation),
            ),
        )
    }

    private suspend fun startCandidate(
        newest: ResolutionResult.Resolved,
        digest: ArtifactDigest,
        committed: CommittedDeployment?,
    ): RealmTarget {
        val generation = DeploymentGeneration((committed?.snapshot?.generation?.value ?: 0L) + 1L)
        val snapshot = DeploymentSnapshot(generation, digest, newest.content)
        return replaceTarget(RealmTarget.Candidate(TargetDeployment(snapshot, newest.manifests), state.nextAttempt(generation)))
    }

    private suspend fun commit(
        candidate: RealmTarget.Candidate,
        eligible: Set<ServiceId>,
    ) = telemetry.artifactSpan(
        "artifact.rollout.commit",
        "artifact-rollout-commit-failed",
        presentation = SpanPresentation("Commit artifact deployment ${candidate.generation.value} for Realm ${realmId.value}"),
    ) { span ->
        span?.annotate {
            attribute("realm.id", realmId.value)
            attribute("deployment.generation", candidate.generation.value)
            attribute("rollout.members", eligible.size.toLong())
        }
        val projections = eligible.associateWith { host -> requireNotNull(members.getValue(host).desired).blob.toApi() }
        state.commit(CommittedDeployment(candidate.deployment.snapshot, projections))
        eligible.forEach { members.getValue(it).recorded = true }
        target = RealmTarget.Committed(candidate.deployment, candidate.generation, candidate.attempt)
    }

    /** Fails [candidate]: the target returns to the committed deployment, which the present members converge back to. */
    private suspend fun revert(
        candidate: RealmTarget.Candidate,
        failures: List<String>,
    ) = telemetry.artifactSpan(
        "artifact.rollout.revert",
        "artifact-rollout-revert-failed",
        presentation = SpanPresentation("Revert artifact deployment ${candidate.generation.value} for Realm ${realmId.value}"),
    ) { span ->
        span?.annotate {
            attribute("realm.id", realmId.value)
            attribute("deployment.generation", candidate.generation.value)
        }
        span?.recordDegraded(ErrorSlug.of("artifact-rollout-candidate-failed"), IllegalStateException(failures.joinToString("; ")))
        val committed = state.committed()
        val deployment =
            committed?.let { current ->
                val manifests =
                    if (current.snapshot.contentDigest == candidate.deployment.snapshot.contentDigest) {
                        candidate.deployment.manifests
                    } else {
                        contents.manifests(current.snapshot.content)
                    }
                manifests?.let { TargetDeployment(current.snapshot, it) }
            }
        if (committed != null && deployment == null) {
            target = null
            forgetAllBut(emptySet())
        } else {
            replaceTarget(
                RealmTarget.Committed(deployment, candidate.generation, state.nextAttempt(candidate.generation), reverting = true),
            )
        }
    }

    private suspend fun recordJoined(
        target: RealmTarget.Committed,
        eligible: Set<ServiceId>,
    ) {
        if (target.deployment == null) return
        val joined =
            eligible
                .map { it to members.getValue(it) }
                .filter { (_, member) -> member.proven && !member.recorded }
        if (joined.isEmpty()) return
        state.recordProjections(joined.associate { (host, member) -> host to requireNotNull(member.desired).blob.toApi() })
        joined.forEach { (_, member) -> member.recorded = true }
    }

    private suspend fun join(
        target: RealmTarget,
        selection: RealmDeploymentSelection,
        host: ServiceId,
    ): Member {
        val desired =
            target.deployment?.let { deployment ->
                projections.publish(deployment.snapshot.projectFor(realmId.value, selection, host, deployment.manifests))
            }
        val renewal = renewed.remove(host)
        val attempt = if (renewal) state.nextAttempt(target.generation) else target.attempt
        return Member(timeSource.markNow(), desired, attempt, reload = renewal)
    }

    private suspend fun converge(
        commands: CoroutineScope,
        target: RealmTarget,
        host: ServiceId,
        member: Member,
        status: ParticipantStatus?,
    ) {
        if (member.command?.isActive == true) return
        val step =
            status?.phase?.step(
                member.desired,
                commitOpen = target is RealmTarget.Committed || commitOpen,
                reload = member.reload,
            ) ?: return
        member.reload = false
        val attempt = member.attemptFor(step.reference) { state.nextAttempt(target.generation) }
        member.command =
            commands.launch {
                val replies =
                    messenger.command(
                        ApplyRolloutCommandRequest(attempt = attempt, command = step.toContract(host)),
                        timings.command,
                    )
                val reply = replies.firstOrNull { it.serviceId == host.value }
                if (reply != null && reply !is ApplyRolloutCommandResponse.AcceptedWrapper) member.failure = reply.describe()
            }
    }

    private fun replaceTarget(next: RealmTarget): RealmTarget {
        target = next
        commitOpen = false
        forgetAllBut(emptySet())
        return next
    }

    private fun forgetAllBut(keep: Set<ServiceId>) {
        (members.keys - keep).forEach { host -> members.remove(host)?.command?.cancel() }
        renewed.retainAll(keep)
    }

    /**
     * One member's convergence toward its projection of one target: when it joined, what it should run (null for
     * nothing), and the healthy interval and failure observed so far.
     */
    private inner class Member(
        val joined: TimeMark,
        val desired: ProjectionReference?,
        private var attempt: RolloutAttempt,
        var reload: Boolean,
    ) {
        private var anchor: ProjectionReference? = null
        private var healthySince: TimeMark? = null
        var command: Job? = null
        var recorded = false

        @Volatile
        var failure: String? = null

        /** Whether the last observation showed the member running its projection, healthy or not. */
        var runsDesired = false
            private set

        /** Whether the last observation showed the member reporting its projection unhealthy. */
        private var unhealthy = false
        private var everProven = false

        val proven: Boolean
            get() = healthySince?.let { it.elapsedNow() >= timings.healthy } == true

        /**
         * Whether a member of the committed target needs a new try: a command failed, it never proved its projection
         * within the deadline, or it reports the projection it proved unhealthy. A missing reply alone is no reason.
         */
        val stuck: Boolean
            get() = failure != null || (!everProven && overdueReason() != null) || (everProven && unhealthy)

        fun observe(status: ParticipantStatus?) {
            val phase = status?.phase
            val running = (phase as? ParticipantPhase.ActiveWrapper)?.value?.current
            runsDesired = if (desired == null) phase == ParticipantPhase.IDLE else running?.projection == desired
            unhealthy = runsDesired && running?.health is ProjectionHealth.UnhealthyWrapper
            val healthy = desired == null || running?.health == ProjectionHealth.HEALTHY
            healthySince = if (runsDesired && healthy) healthySince ?: timeSource.markNow() else null
            if (proven) everProven = true
        }

        /** Why the member is late, when it has not proved its projection within the deadline of joining. */
        fun overdueReason(): String? =
            "did not run its projection healthy within ${timings.memberDeadline}"
                .takeIf { !proven && joined.elapsedNow() >= timings.memberDeadline }

        /** Whether the member staged or runs its projection, which a candidate's commit waits for on every member. */
        fun holds(status: ParticipantStatus?): Boolean =
            when (val phase = status?.phase) {
                is ParticipantPhase.StagedWrapper -> phase.value.candidate == desired
                is ParticipantPhase.ActiveWrapper -> phase.value.current.projection == desired
                else -> false
            }

        /** The attempt a command for [reference] carries: a participant binds one projection to each attempt. */
        suspend fun attemptFor(
            reference: ProjectionReference,
            next: suspend () -> RolloutAttempt,
        ): RolloutAttempt {
            if (anchor != null && anchor != reference) attempt = next()
            anchor = reference
            return attempt
        }
    }
}

/** What the Realm wants its members to run, under the attempt and generation its commands start from. */
private sealed interface RealmTarget {
    /** The deployment to run, or null for nothing: a first candidate failed before anything was committed. */
    val deployment: TargetDeployment?
    val generation: DeploymentGeneration
    val attempt: RolloutAttempt

    /** The committed deployment; [reverting] while the members of a failed candidate still return to it. */
    data class Committed(
        override val deployment: TargetDeployment?,
        override val generation: DeploymentGeneration,
        override val attempt: RolloutAttempt,
        val reverting: Boolean = false,
    ) : RealmTarget

    data class Candidate(
        override val deployment: TargetDeployment,
        override val attempt: RolloutAttempt,
    ) : RealmTarget {
        override val generation: DeploymentGeneration get() = deployment.snapshot.generation
    }

    /** Whether [presence]'s host API can run this target's runtimes for its roles; nothing runs anywhere. */
    fun runsOn(presence: RealmHostPresence): Boolean {
        val deployment = deployment ?: return true
        val api = ArtifactVersion(presence.hostApi)
        val content = deployment.snapshot.content
        val runtimes =
            buildList {
                if (RuntimePlacement.REALM.toSkir() in presence.assignedRoles) addAll(listOf(content.realm, content.panelEngine))
                if (RuntimePlacement.PRIMARY_ENGINE.toSkir() in presence.assignedRoles) add(content.primaryEngine)
            }
        return runtimes.all { deployment.supports(it, api) }
    }
}

private data class TargetDeployment(
    val snapshot: DeploymentSnapshot,
    val manifests: Map<ArtifactId, ImprintManifest>,
) {
    fun supports(
        artifact: DeploymentArtifact,
        api: ArtifactVersion,
    ): Boolean = (manifests[artifact.coordinate.id] as? HostedArtifactManifest)?.hostApi?.accepts(api) == true
}

/** The next command that moves a participant in this phase toward [desired], or null when none is due. */
internal sealed interface MemberStep {
    /** The projection the command binds its attempt to. */
    val reference: ProjectionReference

    data class Stage(
        override val reference: ProjectionReference,
    ) : MemberStep

    data class Commit(
        override val reference: ProjectionReference,
    ) : MemberStep

    data class Abort(
        override val reference: ProjectionReference,
    ) : MemberStep

    /** Restores the projection [reference] replaced, exactly [restore], or nothing when [restore] is null. */
    data class RollBack(
        override val reference: ProjectionReference,
        val restore: ProjectionReference?,
    ) : MemberStep

    fun toContract(host: ServiceId): RolloutCommand {
        val own = listOf(ParticipantProjection(serviceId = host.value, projection = reference))
        return when (this) {
            is Stage -> {
                RolloutCommand.createStage(participants = own)
            }

            is Commit -> {
                RolloutCommand.createCommit(participants = own)
            }

            is Abort -> {
                RolloutCommand.createAbort(participants = own)
            }

            is RollBack -> {
                RolloutCommand.createRollBack(
                    participants =
                        listOf(
                            ParticipantRollback(
                                serviceId = host.value,
                                projection = reference,
                                target = restore?.let(RollbackTarget::ProjectionWrapper) ?: RollbackTarget.EMPTY,
                            ),
                        ),
                )
            }
        }
    }
}

/**
 * The next step toward [desired] (null for running nothing) from this phase. A staged projection is committed only
 * when [commitOpen]; a member already running [desired] is staged again only when [reload] asks to replace it.
 */
internal fun ParticipantPhase.step(
    desired: ProjectionReference?,
    commitOpen: Boolean,
    reload: Boolean,
): MemberStep? =
    when (this) {
        is ParticipantPhase.StagedWrapper -> value.step(desired, commitOpen)
        is ParticipantPhase.ActiveWrapper -> value.step(desired, reload)
        ParticipantPhase.IDLE -> desired?.let(MemberStep::Stage)
        else -> null
    }

private fun StagedCandidate.step(
    desired: ProjectionReference?,
    commitOpen: Boolean,
): MemberStep? =
    when {
        candidate == desired -> MemberStep.Commit(candidate).takeIf { commitOpen }
        desired == null || baseline?.projection == desired -> MemberStep.Abort(candidate)
        else -> MemberStep.Stage(desired)
    }

private fun ActiveParticipant.step(
    desired: ProjectionReference?,
    reload: Boolean,
): MemberStep? {
    val running = current.projection
    return when {
        running == desired -> MemberStep.Stage(desired).takeIf { reload }
        desired == null || retained == desired -> MemberStep.RollBack(running, retained)
        else -> MemberStep.Stage(desired)
    }
}

private fun ApplyRolloutCommandResponse.describe(): String =
    when (this) {
        is ApplyRolloutCommandResponse.StaleAttemptErrorWrapper -> "the attempt was stale"
        is ApplyRolloutCommandResponse.AttemptConflictErrorWrapper -> "the attempt conflicts with another projection"
        is ApplyRolloutCommandResponse.CommandRejectedErrorWrapper -> "the command was rejected: ${value.reason}"
        is ApplyRolloutCommandResponse.CommandFailedErrorWrapper -> "the command failed: ${value.reason}"
        else -> "the command failed"
    }
