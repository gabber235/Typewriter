package com.typewritermc.loader.testing

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.rollout.ArtifactHostAssignment
import com.typewritermc.loader.rollout.DesiredHostExecution
import com.typewritermc.loader.rollout.ExecutionRevision
import com.typewritermc.loader.rollout.HostAssignmentRuntime
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.services.libs.registrar.ServiceId
import skirout.service.v1.rollout.ParticipantStatus

fun desired(
    revision: Long,
    assignment: ArtifactHostAssignment?,
) = DesiredHostExecution(ExecutionRevision(ServiceId("service"), revision), assignment)

class TestRuntime(
    override val assignment: ArtifactHostAssignment,
) : HostAssignmentRuntime {
    override val status: ParticipantStatus? = null
    var failClose = false
    var closeCalls = 0

    override suspend fun replaceSession(session: HostedMessagingSession?) = Unit

    override suspend fun close() {
        closeCalls++
        check(!failClose) { "Runtime shutdown failed" }
    }
}

val assignment = ArtifactHostAssignment(RealmId("realm"), setOf(RuntimePlacement.PRIMARY_ENGINE))
