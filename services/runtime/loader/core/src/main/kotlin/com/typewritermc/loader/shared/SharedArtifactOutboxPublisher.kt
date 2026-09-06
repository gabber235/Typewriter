package com.typewritermc.loader.shared

import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.ProducerMetadata
import com.typewritermc.loader.api.artifact.SharedArtifactChanged
import com.typewritermc.loader.api.artifact.SharedArtifactDescriptor
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.skir.asPayloadCodec
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import skirout.service.v1.artifact.ProducerMetadataEntry
import kotlin.coroutines.coroutineContext
import kotlin.time.Duration.Companion.seconds
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm
import skirout.service.v1.artifact.ProducerMetadata as SkirProducerMetadata
import skirout.service.v1.artifact.SharedArtifactChanged as SkirSharedArtifactChanged
import skirout.service.v1.artifact.SharedArtifactDescriptor as SkirSharedArtifactDescriptor
import skirout.service.v1.artifact.SharedArtifactProvenance as SkirSharedArtifactProvenance

data class SharedArtifactChangeAddress(
    val organizationId: String,
    val realmId: String,
)

val SharedArtifactChangedContract =
    EventContract(
        OperationName.of("realm.shared.changed"),
        sharedChangeAddress(),
        SkirSharedArtifactChanged.serializer.asPayloadCodec(),
        ErrorSlug.of("realm-shared-change-failed"),
    )

/**
 * Drains persisted changes through each ready registrar session.
 *
 * Construction starts a worker in the supplied scope. Session replacement cancels the current drain. Only
 * successful publication acknowledges an event, so consumers must tolerate duplicates after interrupted
 * acknowledgment.
 */
class SharedArtifactOutboxPublisher(
    scope: CoroutineScope,
    states: StateFlow<RegistrarSnapshot>,
    private val communicatorFor: suspend (Long) -> RegistrarResult<Communicator>,
    private val repositories: () -> Collection<FileSharedArtifactRepository>,
) : AutoCloseable {
    private val publisher: Job =
        scope.launch {
            states.collectLatest { snapshot ->
                val ready = snapshot.state as? RegistrarState.Ready ?: return@collectLatest
                val communicator =
                    when (val result = communicatorFor(ready.connectionGeneration)) {
                        is RegistrarResult.Success -> result.value
                        is RegistrarResult.Failure -> return@collectLatest
                    }
                publishPending(ready.session.binding.organizationId, communicator)
            }
        }

    private suspend fun publishPending(
        organizationId: String,
        communicator: Communicator,
    ) {
        while (true) {
            coroutineContext.ensureActive()
            val pending = repositories().flatMap { repository -> repository.pendingChanges().map { repository to it } }
            if (pending.isEmpty()) {
                delay(1.seconds)
                continue
            }
            pending.forEach { (repository, change) ->
                val result =
                    communicator.publish(
                        SharedArtifactChangedContract,
                        SharedArtifactChangeAddress(organizationId, change.realmId),
                        change.toSkir(),
                    )
                if (result is CommunicationResult.Success) {
                    repository.acknowledge(change)
                } else {
                    delay(1.seconds)
                    return@forEach
                }
            }
        }
    }

    /**
     * Cancels and joins the publisher before repositories or transport are released.
     */
    suspend fun stop() {
        publisher.cancelAndJoin()
    }

    /**
     * Requests worker cancellation without awaiting completion.
     *
     * Use [stop] for an awaited shutdown boundary.
     */
    override fun close() {
        publisher.cancel()
    }
}

private fun sharedChangeAddress(): AddressTemplate<SharedArtifactChangeAddress> =
    addressTemplate(
        "typewriter.organization.{organization}.realm.{realm}.shared.changed",
        { address ->
            addressValuesOf(
                "organization" to address.organizationId,
                "realm" to address.realmId,
            )
        },
        { values ->
            SharedArtifactChangeAddress(
                values.require("organization"),
                values.require("realm"),
            )
        },
    )

private fun SharedArtifactChanged.toSkir(): SkirSharedArtifactChanged =
    SkirSharedArtifactChanged(
        realmId = realmId,
        artifact = artifact.toSkir(),
        catalogRevision = catalogRevision.value,
    )

private fun SharedArtifactDescriptor.toSkir(): SkirSharedArtifactDescriptor =
    SkirSharedArtifactDescriptor(
        id = id.value,
        revision = revision.value,
        label = label,
        mediaType = mediaType,
        digest = digest?.toSkir(),
        size = size,
        metadata = metadata?.toSkir(),
        provenance = provenance.toSkir(),
        deleted = deleted,
    )

private fun ArtifactDigest.toSkir(): SkirArtifactDigest =
    SkirArtifactDigest(
        algorithm = SkirDigestAlgorithm.SHA256,
        value = value,
    )

private fun ProducerMetadata.toSkir(): SkirProducerMetadata =
    SkirProducerMetadata(
        entries =
            values.entries
                .sortedBy { it.key }
                .map { ProducerMetadataEntry(key = it.key, value = it.value) },
    )

private fun SharedArtifactProvenance.toSkir(): SkirSharedArtifactProvenance =
    when (this) {
        is SharedArtifactProvenance.LocalInbox -> {
            SkirSharedArtifactProvenance.createLocalInbox(relativePath = relativePath)
        }

        is SharedArtifactProvenance.PanelUpload -> {
            SkirSharedArtifactProvenance.createPanel(userId = userId)
        }

        is SharedArtifactProvenance.HostedRuntime -> {
            SkirSharedArtifactProvenance.createService(hostId = hostId, runtimeId = runtimeId)
        }
    }
