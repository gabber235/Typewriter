package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.runtime.EngineDeploymentEntrypoint
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.EngineImplementationArtifact
import com.typewritermc.loader.api.EngineImplementationTarget
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedArtifactPackage
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeDirectories
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.HostedRuntimeIdentity
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import java.nio.file.Path

private val manifest =
    EngineManifest(
        id = ArtifactId("typewritermc:paper"),
        version = ArtifactVersion("1.0.0"),
        hostApi = VersionConstraint("^1"),
        runtimeEntrypointClass = EngineDeploymentEntrypoint::class.java.name,
        directCapabilities = emptyList(),
        resolvedCapabilities = emptyList(),
        bundledComponents = emptyList(),
        contributions = emptyList(),
    )

private fun target(placement: RuntimePlacement) =
    EngineImplementationTarget(
        placement = placement,
        engine = EngineImplementationArtifact(manifest.id, manifest.version, ArtifactDigest.sha256(byteArrayOf(1)), emptyList()),
        extensions = emptyList(),
    )

/** A deployment of [runtime] placement; staging must refuse it before it reads artifacts or the host. */
fun deploymentContext(
    runtime: RuntimePlacement,
    implementation: RuntimePlacement?,
) = HostedDeploymentContext(
    identity = HostedRuntimeIdentity(serviceId = "host", realmId = "realm", placement = runtime),
    directories = HostedRuntimeDirectories(Path.of("state"), Path.of("deployment")),
    artifacts = HostedArtifactPackage(HostedArtifact(Path.of("engine.jar"), manifest), emptyList(), emptyList()),
    publicationTarget = target(RuntimePlacement.PRIMARY_ENGINE),
    engineImplementation = implementation?.let(::target),
    facts = emptyMap(),
    host = UnusedHost,
)

/** A host whose every member fails: a refused deployment must never reach messaging, telemetry or shared artifacts. */
private object UnusedHost : HostedRuntimeHost {
    override val messaging get() = error("A refused deployment never reaches messaging.")
    override val openTelemetry get() = error("A refused deployment never reaches telemetry.")
    override val sharedArtifacts get() = error("A refused deployment never reaches shared artifacts.")
}
