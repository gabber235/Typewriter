package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.RuntimePlacement

data class ExecutionRevision(
    val serviceId: String,
    val value: Long,
)

/** A null revision selects standalone execution; a null assignment requests complete removal. */
data class DesiredHostExecution(
    val revision: ExecutionRevision?,
    val assignment: ArtifactHostAssignment?,
)

internal interface HostAssignmentRuntime {
    val assignment: ArtifactHostAssignment
    val status: ParticipantStatus?

    suspend fun replaceSession(session: HostedMessagingSession?)

    suspend fun close()
}

internal data class HostExecutionObservation(
    val revision: ExecutionRevision,
    val roles: Set<RuntimePlacement>,
    val status: ParticipantStatus?,
)

/**
 * Owns applied intent, held resources, and report delivery independently.
 * The caller serializes operations and supplies the newest intent on each retry. Failed cleanup retains ownership;
 * an empty first assignment still produces an observation. Transport failure never rolls back completed cleanup.
 */
internal class HostExecutionOwner(
    private val create: (ArtifactHostAssignment) -> HostAssignmentRuntime,
) {
    private var runtime: HostAssignmentRuntime? = null
    private var applied: DesiredHostExecution? = null
    private var closing = false
    private var delivered: Pair<HostExecutionObservation, Long>? = null

    val hasRuntime: Boolean get() = runtime != null

    fun isApplied(desired: DesiredHostExecution): Boolean = applied == desired && !closing

    suspend fun apply(
        desired: DesiredHostExecution,
        session: HostedMessagingSession?,
    ) {
        if (isApplied(desired)) return
        applied = null
        delivered = null
        if (closing || runtime?.assignment != desired.assignment) {
            closing = true
            runtime?.close()
            runtime = null
            closing = false
        }
        if (runtime == null) runtime = desired.assignment?.let(create)
        runtime?.replaceSession(session)
        applied = desired
    }

    suspend fun replaceSession(session: HostedMessagingSession?) {
        if (!closing) runtime?.replaceSession(session)
    }

    fun needsReport(
        desired: DesiredHostExecution,
        sessionId: Long?,
    ): Boolean {
        if (!isApplied(desired) || sessionId == null) return false
        val revision = desired.revision ?: return false
        return delivered != (HostExecutionObservation(revision, desired.assignment?.roles.orEmpty(), runtime?.status) to sessionId)
    }

    suspend fun report(
        desired: DesiredHostExecution,
        sessionId: Long?,
        submit: suspend (HostExecutionObservation) -> Unit,
    ) {
        if (!isApplied(desired) || sessionId == null) return
        val revision = desired.revision ?: return
        val observation = HostExecutionObservation(revision, desired.assignment?.roles.orEmpty(), runtime?.status)
        val delivery = observation to sessionId
        if (delivery == delivered) return
        submit(observation)
        delivered = delivery
    }

    suspend fun close() {
        closing = true
        runtime?.close()
        runtime = null
        applied = null
        delivered = null
        closing = false
    }
}
