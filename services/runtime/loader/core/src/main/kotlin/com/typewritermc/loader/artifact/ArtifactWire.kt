package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.ProducerMetadata
import com.typewritermc.loader.api.artifact.SharedArtifactDescriptor
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import skirout.service.v1.artifact.ProducerMetadataEntry
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.BlobMetadata as SkirBlobMetadata
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm
import skirout.service.v1.artifact.ProducerMetadata as SkirProducerMetadata
import skirout.service.v1.artifact.SharedArtifactDescriptor as SkirSharedArtifactDescriptor
import skirout.service.v1.artifact.SharedArtifactProvenance as SkirSharedArtifactProvenance

/*
 * The one place the loader translates artifact values between the loader host API and the Skir artifact contracts.
 * The host API is versioned on its own (hostApi ^1), so its signatures never expose generated protocol types and a
 * contract change cannot break a hosted runtime compiled against it. Decoding goes through the host API constructors,
 * so wire values are checked by the same invariants as locally produced ones.
 */

internal fun ArtifactDigest.toSkir() = SkirArtifactDigest(algorithm = SkirDigestAlgorithm.SHA256, value = value)

internal fun SkirArtifactDigest.toApi(): ArtifactDigest {
    require(algorithm == SkirDigestAlgorithm.SHA256) { "Unsupported artifact digest algorithm." }
    return ArtifactDigest(DigestAlgorithm.SHA_256, value)
}

internal fun BlobMetadata.toSkir() = SkirBlobMetadata(digest = digest.toSkir(), size = size)

internal fun SkirBlobMetadata.toApi() = BlobMetadata(digest.toApi(), size)

/** Orders entries by key so equal metadata always has one wire form. */
internal fun ProducerMetadata.toSkir() =
    SkirProducerMetadata(entries = values.entries.sortedBy { it.key }.map { ProducerMetadataEntry(key = it.key, value = it.value) })

internal fun SkirProducerMetadata.toApi() = ProducerMetadata(entries.associate { it.key to it.value })

internal fun SharedArtifactProvenance.toSkir(): SkirSharedArtifactProvenance =
    when (this) {
        is SharedArtifactProvenance.LocalInbox -> {
            SkirSharedArtifactProvenance.createLocalInbox(relativePath = relativePath)
        }

        is SharedArtifactProvenance.PanelUpload -> {
            SkirSharedArtifactProvenance.createPanel(userId = userId)
        }

        is SharedArtifactProvenance.HostedRuntime -> {
            SkirSharedArtifactProvenance.createService(serviceId = serviceId, runtimeId = runtimeId)
        }
    }

internal fun SkirSharedArtifactProvenance.toApi(): SharedArtifactProvenance =
    when (this) {
        is SkirSharedArtifactProvenance.LocalInboxWrapper -> SharedArtifactProvenance.LocalInbox(value.relativePath)
        is SkirSharedArtifactProvenance.PanelWrapper -> SharedArtifactProvenance.PanelUpload(value.userId)
        is SkirSharedArtifactProvenance.ServiceWrapper -> SharedArtifactProvenance.HostedRuntime(value.serviceId, value.runtimeId)
        else -> error("Unknown shared artifact provenance.")
    }

internal fun SharedArtifactDescriptor.toSkir() =
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

internal fun SkirSharedArtifactDescriptor.toApi() =
    SharedArtifactDescriptor(
        SharedArtifactId(id),
        SharedArtifactRevision(revision),
        label,
        mediaType,
        digest?.toApi(),
        size,
        metadata?.toApi(),
        provenance.toApi(),
        deleted,
    )
