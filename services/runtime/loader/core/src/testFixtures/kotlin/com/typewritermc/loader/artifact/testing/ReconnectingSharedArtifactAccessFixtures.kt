package com.typewritermc.loader.artifact.testing

import com.typewritermc.loader.artifact.toSkir
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse

/** Answers the next request with the metadata of [BLOB], as a Realm host that holds it does. */
fun FakeMessageTransport.answerMetadata() =
    answer(
        RealmRouteScope(realmId = REALM, organizationId = ORGANIZATION).sharedBlobMetadata,
        FetchArtifactBlobMetadataResponse.SuccessWrapper(BLOB.toSkir()),
    )

const val REALM = "quests"

private const val ORGANIZATION = "organization"

/** The artifact blob the Realm host holds. */
val BLOB = "artifact".encodeToByteArray().let { BlobMetadata(ArtifactDigest.sha256(it), it.size.toLong()) }
