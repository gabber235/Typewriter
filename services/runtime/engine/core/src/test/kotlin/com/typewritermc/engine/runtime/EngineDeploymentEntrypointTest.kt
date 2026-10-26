package com.typewritermc.engine.runtime

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
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.nio.file.Path

val EngineDeploymentEntrypointTest by testSuite {
    test("an engine refuses a deployment whose implementation targets another placement") {
        val context = deploymentContext(runtime = RuntimePlacement.PANEL_ENGINE, implementation = RuntimePlacement.PRIMARY_ENGINE)

        shouldThrow<IllegalArgumentException> { EngineDeploymentEntrypoint().stage(context) }.message shouldBe
            "Engine runtime implementation placement does not match the hosted runtime."
    }

    test("an engine refuses a deployment without an implementation") {
        val context = deploymentContext(runtime = RuntimePlacement.PRIMARY_ENGINE, implementation = null)

        shouldThrow<IllegalArgumentException> { EngineDeploymentEntrypoint().stage(context) }.message shouldBe
            "Engine runtime implementation is missing."
    }
}

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
private fun deploymentContext(
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

private object UnusedHost : HostedRuntimeHost {
    override val messaging get() = error("A refused deployment never reaches messaging.")
    override val openTelemetry get() = error("A refused deployment never reaches telemetry.")
    override val sharedArtifacts get() = error("A refused deployment never reaches shared artifacts.")
}
