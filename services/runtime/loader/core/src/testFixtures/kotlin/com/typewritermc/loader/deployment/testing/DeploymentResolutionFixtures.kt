package com.typewritermc.loader.deployment.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.ArtifactProvenance
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.deployment.ArtifactCandidate
import com.typewritermc.loader.deployment.CandidateIndex
import com.typewritermc.loader.deployment.PrimaryEngineTarget
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.RealmLoaderIntent
import com.typewritermc.loader.deployment.resolveDeployment
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId

data class Refusal(
    val name: String,
    val candidates: List<ArtifactCandidate>,
    val problem: String,
)

fun resolve(vararg candidates: ArtifactCandidate) =
    resolveDeployment(
        CandidateIndex(candidates.toList()),
        selection,
        PrimaryEngineTarget(ArtifactId(PAPER), VersionConstraint("^1")),
        RealmLoaderIntent(ArtifactRequirement(ArtifactId(PANEL), VersionConstraint("^1"))),
    )

fun realm(
    version: String,
    hostApi: String = "^1",
    id: String = "typewritermc:realm",
) = candidate(
    ArtifactKind.REALM,
    RealmManifest(
        id = ArtifactId(id),
        version = ArtifactVersion(version),
        hostApi = VersionConstraint(hostApi),
        runtimeEntrypointClass = "fixture.Realm",
        contributions = emptyList(),
    ),
)

fun engine(
    id: String,
    version: String,
    hostApi: String = "^1",
    direct: List<ArtifactRequirement> = emptyList(),
    resolved: List<ResolvedArtifact> = emptyList(),
) = candidate(
    ArtifactKind.ENGINE,
    EngineManifest(
        id = ArtifactId(id),
        version = ArtifactVersion(version),
        hostApi = VersionConstraint(hostApi),
        runtimeEntrypointClass = "fixture.Engine",
        directCapabilities = direct,
        resolvedCapabilities = resolved,
        bundledComponents = emptyList(),
        contributions = emptyList(),
    ),
)

fun requirement(
    id: String,
    constraint: String,
) = ArtifactRequirement(ArtifactId(id), VersionConstraint(constraint))

fun capability(
    id: String,
    version: String,
) = ResolvedArtifact(ArtifactId(id), ArtifactVersion(version), ArtifactKind.CAPABILITY)

private fun candidate(
    kind: ArtifactKind,
    manifest: ImprintManifest,
): ArtifactCandidate {
    val bytes = "${manifest.id.value}@${manifest.version.value}".encodeToByteArray()
    return ArtifactCandidate(
        artifact =
            DeploymentArtifact(
                ArtifactCoordinate(manifest.id, manifest.version),
                kind,
                ArtifactDigest.sha256(bytes),
                bytes.size.toLong(),
            ),
        manifest = manifest,
        provenance = ArtifactProvenance.LocalInbox("manual/${manifest.id.value}.jar", 1),
        importRevision = 1,
    )
}

const val PAPER = "typewritermc:paper"

const val PANEL = "typewritermc:panel"

private val REALM_HOST = ServiceId("realm-host")

private val PRIMARY_HOST = ServiceId("primary-host")

/** A Realm host and a primary engine host that both run host API 1.0.0. */
val selection =
    RealmDeploymentSelection(
        realmService = REALM_HOST,
        primaryEngineServices = setOf(PRIMARY_HOST),
        serviceApis = mapOf(REALM_HOST to ArtifactVersion("1.0.0"), PRIMARY_HOST to ArtifactVersion("1.0.0")),
    )
