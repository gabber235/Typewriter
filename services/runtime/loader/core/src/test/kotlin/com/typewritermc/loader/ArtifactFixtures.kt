package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest

/** The version of every fixture artifact, and the host API version fixture hosts run. */
internal val FIXTURE_VERSION = ArtifactVersion("1.0.0")

/** A deployment artifact whose bytes are [content], at [FIXTURE_VERSION]. */
internal fun deploymentArtifact(
    id: String,
    kind: ArtifactKind,
    content: String,
): DeploymentArtifact {
    val bytes = content.encodeToByteArray()
    return DeploymentArtifact(ArtifactCoordinate(ArtifactId(id), FIXTURE_VERSION), kind, ArtifactDigest.sha256(bytes), bytes.size.toLong())
}

/** The manifest of an engine [artifact] with no capabilities, components or contributions. */
internal fun engineManifest(artifact: DeploymentArtifact): EngineManifest =
    EngineManifest(
        id = artifact.coordinate.id,
        version = artifact.coordinate.version,
        hostApi = VersionConstraint("^1"),
        runtimeEntrypointClass = "fixture.Runtime",
        directCapabilities = emptyList(),
        resolvedCapabilities = emptyList(),
        bundledComponents = emptyList(),
        contributions = emptyList(),
    )
