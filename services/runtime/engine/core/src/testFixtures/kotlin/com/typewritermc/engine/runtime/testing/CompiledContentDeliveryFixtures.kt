@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.runtime.MessagingEngineContentDelivery
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse

private const val REALM = "realm"
private val queryAddress = RealmRouteScope(organizationId = "organization", realmId = REALM)

/** The deadline the authoring compiled query waits for an answer before it times out. */
val queryDeadline get() = queryAddress.authoringCompiledQuery.timeout

/** A content delivery for [REALM] over a communicator on [transport], with its host built by [deliveryHost]. */
fun TestScope.delivery(
    transport: FakeMessageTransport,
    telemetry: TelemetryTestHarness,
) = MessagingEngineContentDelivery(
    deliveryHost(
        HostedMessagingSession(1, "organization", Communicator(transport, telemetry.telemetry, ContextPropagators.noop())),
        telemetry,
    ),
    REALM,
    backgroundScope,
)

/** The reply of a realm that has no published content: the query answers with an absent response. */
fun absentContentReply(request: OutboundMessage): TransportResult<InboundMessage> =
    TransportResult.Success(
        InboundMessage(
            request.address,
            queryAddress.authoringCompiledQuery.responseCodec.encode(QueryPublishedContentResponse.createAbsent()),
        ),
    )

/** A runtime host with [session] as its messaging session; shared artifact calls fail, as no test uses them. */
fun deliveryHost(
    session: HostedMessagingSession,
    telemetry: TelemetryTestHarness,
) = object : HostedRuntimeHost {
    override val messaging = MutableStateFlow<HostedMessagingSession?>(session)
    override val openTelemetry = telemetry.openTelemetry
    override val sharedArtifacts =
        object : SharedArtifactAccess {
            override suspend fun publish(command: PublishSharedArtifact): Nothing = error("No content was returned")

            override suspend fun delete(
                id: SharedArtifactId,
                expectedRevision: SharedArtifactRevision,
                provenance: SharedArtifactProvenance,
            ): Nothing = error("No content was returned")

            override suspend fun catalog(): Nothing = error("No content was returned")

            override suspend fun metadata(digest: ArtifactDigest): Nothing = error("No content was returned")

            override suspend fun fetch(digest: ArtifactDigest): Nothing = error("No content was returned")

            override suspend fun store(
                expected: BlobMetadata,
                content: ByteArray,
            ): Nothing = error("No content was returned")
        }
}
