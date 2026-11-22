package com.typewritermc.engine.paper

import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.imprint.archive.ImprintArchive
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.deployment.HostDeploymentProjectionCodec
import com.typewritermc.loader.rollout.FileRolloutStateRepository
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.realm.realmProviderArtifacts
import java.nio.file.Files
import java.nio.file.Path

/**
 * The artifacts the stack's Realm loads, read from where its host keeps the artifacts of its Realm's committed
 * deployment: `STACK_REALM_HOST_ARTIFACTS`, which `cargo xtask e2e game` hands the test JVM. They are the Realm host's own
 * runtimes and the extensions it deployed, chosen as the Realm itself chooses them.
 */
internal suspend fun stackRealmArtifacts(): List<GeneratedProviderArtifact> =
    realmArtifacts(Path.of(stackValue("STACK_REALM_HOST_ARTIFACTS")), RealmId(stackValue("STACK_REALM")))

private suspend fun realmArtifacts(
    root: Path,
    realm: RealmId,
): List<GeneratedProviderArtifact> {
    val committed =
        checkNotNull(FileRolloutStateRepository(realm, root).committed()) {
            "the Realm host at $root has committed no deployment of ${realm.value}"
        }
    val blobs = FileDigestBlobStore(root)
    val projection =
        committed.projections.values
            .map { digest -> HostDeploymentProjectionCodec.decode(Files.readAllBytes(blobs.pathFor(digest))) }
            .singleOrNull { projection -> projection.runtimes.any { it.placement == RuntimePlacement.REALM } }
            ?: error("the committed deployment of ${realm.value} at $root places its Realm on no single host")
    val digests = projection.runtimes.map { it.artifact.digest } + projection.extensions.map { it.artifact.digest }
    return realmProviderArtifacts(
        digests.map { digest -> blobs.pathFor(digest).let { path -> HostedArtifact(path, ImprintArchive.require(path)) } },
    )
}
