package com.typewritermc.loader.api.artifact

import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest

/**
 * Retains publication payloads for one Realm on its local host.
 *
 * Reconcile from authoritative saved selection before publishing or collecting. Protect before writing payloads;
 * select only after the publication commit is confirmed. Failed or uncertain commits leave protected roots until
 * a fenced recovery reconciles them. The loader persists roots across normal process restarts.
 */
interface PublicationBlobRetention {
    suspend fun protect(
        publication: String,
        digests: Set<ArtifactDigest>,
    )

    suspend fun selected(publication: String)

    suspend fun reconcile(selected: PublicationBlobRoots?)
}

data class PublicationBlobRoots(
    val publication: String,
    val digests: Set<ArtifactDigest>,
)
