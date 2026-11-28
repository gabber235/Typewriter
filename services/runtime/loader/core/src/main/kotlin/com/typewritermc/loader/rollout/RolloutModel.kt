package com.typewritermc.loader.rollout

import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import skirout.service.v1.rollout.ProjectionReference

/** Identifies the logical Realm whose hosts [RealmRollout] keeps on one deployment. */
@JvmInline
@Serializable
value class RealmId(
    val value: String,
)

/**
 * Records a snapshot accepted after rollout stability checks and the exact projection each host runs for it.
 *
 * The rollout converges a recorded host back to exactly its projection without choosing new artifact content or
 * needing the snapshot's manifests; artifact maintenance keeps the projection blobs alive.
 */
@Serializable
data class CommittedDeployment(
    val snapshot: DeploymentSnapshot,
    val projections: Map<
        ServiceId,
        @Serializable(with = ProjectionReferenceAsSkirJson::class)
        ProjectionReference,
    >,
)

/** Stores a [ProjectionReference] as its Skir JSON form, so the stored reference keeps every field of the contract. */
internal object ProjectionReferenceAsSkirJson : KSerializer<ProjectionReference> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("com.typewritermc.loader.rollout.ProjectionReference", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: ProjectionReference,
    ) = encoder.encodeString(ProjectionReference.serializer.toJsonCode(value))

    override fun deserialize(decoder: Decoder): ProjectionReference = ProjectionReference.serializer.fromJsonCode(decoder.decodeString())
}
