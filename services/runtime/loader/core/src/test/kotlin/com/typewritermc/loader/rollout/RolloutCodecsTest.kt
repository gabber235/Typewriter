package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RolloutCodecsTest by testSuite {
    val realm = RealmId("realm")
    val service = ServiceId("service")
    val attempt = RolloutAttempt(1, DeploymentGeneration(2))
    val projection =
        ProjectionReference(
            realm,
            attempt.generation,
            service,
            ArtifactDigest.sha256("projection".encodeToByteArray()),
            mapOf(
                RuntimePlacement.REALM to ArtifactVersion("1.0.0"),
                RuntimePlacement.PRIMARY_ENGINE to ArtifactVersion("2.0.0"),
            ),
        )
    val active = ActiveProjectionReference(projection, RuntimeHealthSnapshot.Healthy)
    val presentBaseline = ActiveBaseline.Present(active)

    test("every rollout command keeps its native value graph") {
        val commands =
            listOf(
                RolloutCommand.Stage,
                RolloutCommand.Commit,
                RolloutCommand.Abort,
                RolloutCommand.Rollback(mapOf(service to RollbackTarget.Empty)),
                RolloutCommand.Rollback(mapOf(service to RollbackTarget.Projection(projection))),
            )

        commands.forEach { command ->
            val envelope = RolloutEnvelope(realm, attempt, setOf(service), mapOf(service to projection), command)
            RolloutCodecs.commandRequest.roundTrip(envelope) shouldBe envelope
        }
    }

    test("every participant status keeps its recovery state") {
        val statuses =
            listOf(
                ParticipantStatus.Idle(attempt, service),
                ParticipantStatus.Staging(attempt, service, projection, ActiveBaseline.Empty),
                ParticipantStatus.Staged(attempt, service, projection, presentBaseline),
                ParticipantStatus.Committing(attempt, service, projection, presentBaseline),
                ParticipantStatus.Active(attempt, service, active, RetainedProjection.None),
                ParticipantStatus.Active(attempt, service, active, RetainedProjection.Present(projection)),
                ParticipantStatus.Aborting(attempt, service, projection, presentBaseline),
                ParticipantStatus.RollingBack(attempt, service, projection, RollbackTarget.Empty),
                ParticipantStatus.RollingBack(attempt, service, projection, RollbackTarget.Projection(projection)),
                ParticipantStatus.Failed(
                    attempt,
                    service,
                    RolloutCommandKind.COMMIT,
                    RecoverableParticipantState.Empty,
                    "empty failure",
                ),
                ParticipantStatus.Failed(
                    attempt,
                    service,
                    RolloutCommandKind.ROLLBACK,
                    RecoverableParticipantState.Active(active, RetainedProjection.Present(projection)),
                    "active failure",
                ),
                ParticipantStatus.Failed(
                    attempt,
                    service,
                    RolloutCommandKind.STAGE,
                    RecoverableParticipantState.Staged(projection, presentBaseline),
                    "staged failure",
                ),
            )

        statuses.forEach { status ->
            val event = ParticipantStateChanged(realm, status)
            RolloutCodecs.participantState.roundTrip(event) shouldBe event
            RolloutCodecs.statusReply.roundTrip(ParticipantStatusReply.Status(service, status)) shouldBe
                ParticipantStatusReply.Status(service, status)
        }
    }

    test("probe and response codecs keep every response variant") {
        val probe = ProbeRealmHosts(realm, "probe")
        RolloutCodecs.probeRequest.roundTrip(probe) shouldBe probe

        val presence =
            RealmHostPresence(
                probe.probeId,
                service,
                ArtifactVersion("1.0.0"),
                setOf(RuntimePlacement.REALM, RuntimePlacement.PRIMARY_ENGINE),
                ActiveProjectionReference(projection, RuntimeHealthSnapshot.Unhealthy(listOf("unhealthy"))),
            )
        listOf<PresenceReply>(PresenceReply.Present(presence), PresenceReply.Failed("failed")).forEach { response ->
            RolloutCodecs.presenceReply.roundTrip(response) shouldBe response
        }

        val statusProbe = ProbeParticipantStatus(realm, attempt)
        RolloutCodecs.statusRequest.roundTrip(statusProbe) shouldBe statusProbe
        val failure = ParticipantStatusReply.InternalFailure(service, "failed")
        RolloutCodecs.statusReply.roundTrip(failure) shouldBe failure

        val acceptances =
            listOf(
                CommandAcceptance(service, accepted = true),
                CommandAcceptance(service, accepted = false, reason = "rejected"),
                CommandAcceptance(service, accepted = false, reason = "failed", internalFailure = true),
            )
        acceptances.forEach { response -> RolloutCodecs.commandResponse.roundTrip(response) shouldBe response }
    }
}

private fun <Value : Any> PayloadCodec<Value>.roundTrip(value: Value): Value = decode(encode(value))
