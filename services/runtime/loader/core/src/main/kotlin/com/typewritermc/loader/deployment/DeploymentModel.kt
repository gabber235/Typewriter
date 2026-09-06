package com.typewritermc.loader.deployment

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.artifact.ArtifactDigest
import com.typewritermc.loader.artifact.DeploymentArtifact
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.encodeToByteArray

const val CURRENT_DEPLOYMENT_FORMAT = 1

/**
 * Selects exact artifacts for the Realm, both engine roles, and extensions.
 *
 * Role kinds and unique extension identities are enforced. Canonicalization sorts extensions so arrival order does
 * not alter the encoded content digest.
 */
@Serializable
data class DeploymentContent(
    val format: Int = CURRENT_DEPLOYMENT_FORMAT,
    val realm: DeploymentArtifact,
    val primaryEngine: DeploymentArtifact,
    val panelEngine: DeploymentArtifact,
    val extensions: List<DeploymentArtifact>,
) {
    init {
        require(realm.kind == com.typewritermc.imprint.ArtifactKind.REALM) { "Realm content requires a Realm artifact." }
        require(primaryEngine.kind == com.typewritermc.imprint.ArtifactKind.ENGINE) {
            "Primary engine content requires an engine artifact."
        }
        require(panelEngine.kind == com.typewritermc.imprint.ArtifactKind.ENGINE) {
            "Panel engine content requires an engine artifact."
        }
        require(extensions.all { it.kind == com.typewritermc.imprint.ArtifactKind.EXTENSION }) {
            "Extension content may contain only extension artifacts."
        }
        require(extensions.map { it.coordinate.id }.distinct().size == extensions.size) {
            "A deployment may select one version of each extension."
        }
    }

    fun canonical(): DeploymentContent =
        copy(
            extensions =
                extensions.sortedWith(
                    compareBy(
                        { it.coordinate.id.value },
                        { it.coordinate.version },
                        { it.digest.value },
                    ),
                ),
        )
}

@JvmInline
@Serializable
value class DeploymentGeneration(
    val value: Long,
) {
    init {
        require(value >= 1) { "Deployment generation must be positive." }
    }
}

/**
 * Binds a deployment generation to canonical selected content.
 *
 * Construction recomputes the digest and rejects mismatches. Generation orders deployments independently of
 * artifact versions.
 */
@Serializable
data class DeploymentSnapshot(
    val generation: DeploymentGeneration,
    val contentDigest: ArtifactDigest,
    val content: DeploymentContent,
) {
    init {
        require(contentDigest == DeploymentContentCodec.digest(content)) { "Deployment content digest does not match content." }
    }
}

@Serializable
data class PrimaryEngineTarget(
    val id: ArtifactId,
    val version: VersionConstraint,
)

@Serializable
data class RealmLoaderIntent(
    val panelEngine: ArtifactRequirement,
)

/**
 * Encodes canonical deployment content as CBOR with defaults included and computes its SHA256 identity.
 *
 * Digest equality reflects selected content rather than extension list arrival order.
 */
@OptIn(ExperimentalSerializationApi::class)
object DeploymentContentCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(content: DeploymentContent): ByteArray = cbor.encodeToByteArray(content.canonical())

    fun digest(content: DeploymentContent): ArtifactDigest = ArtifactDigest.sha256(encode(content))
}
