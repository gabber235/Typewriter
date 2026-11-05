package com.typewritermc.loader.rollout.testing

import com.typewritermc.loader.artifact.toSkir
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.rolloutCommand
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantProjection
import skirout.service.v1.rollout.ProjectionReference

fun participant(serviceId: String) =
    ParticipantProjection(
        serviceId = serviceId,
        projection =
            ProjectionReference.partial(
                realmId = "realm",
                generation = 1,
                serviceId = serviceId,
                blob = ArtifactDigest.sha256(serviceId.encodeToByteArray()).toSkir(),
            ),
    )

/** Delivers [response] to [replyTo] as the rollout participant answers a command it received on [scope]. */
fun deliverRolloutReply(
    transport: FakeMessageTransport,
    scope: RealmRouteScope,
    replyTo: MessageAddress,
    response: ApplyRolloutCommandResponse,
) = transport.deliver(
    TransportDelivery.Message(
        InboundMessage(
            replyTo,
            scope.rolloutCommand.responseCodec
                .encode(response)
                .toByteArray(),
        ),
    ),
)
