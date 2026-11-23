package com.typewritermc.engine.runtime.testing

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
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import java.nio.file.Path

private val manifest =
    EngineManifest(
        id = ArtifactId("typewritermc:paper"),
        version = ArtifactVersion("1.0.0"),
        hostApi = VersionConstraint("^1"),
        runtimeEntrypointClass = "com.typewritermc.engine.paper.PaperEngineEntrypoint",
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
    identity = HostedRuntimeIdentity(serviceId = "host", realmId = "realm", placement = runtime, engineId = "engine"),
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

/**
 * A primary engine deployment of engine [engine] in Realm `realm` of organization `organization`, whose host messaging
 * reaches [buckets] and sends through [transport].
 */
fun wiredDeploymentContext(
    buckets: com.typewritermc.services.libs.communicator.kv.KeyValueBuckets =
        com.typewritermc.services.libs.communicator.testing.UnreachableKeyValueBuckets,
    engine: String = "engine",
    transport: com.typewritermc.services.libs.communicator.transport.MessageTransport =
        com.typewritermc.services.libs.communicator.testing
            .FakeMessageTransport(),
): HostedDeploymentContext {
    val context = deploymentContext(RuntimePlacement.PRIMARY_ENGINE, RuntimePlacement.PRIMARY_ENGINE)
    return context.copy(identity = context.identity.copy(engineId = engine), host = MessagingHost(buckets, transport))
}

/** A host whose messaging session reaches [buckets] and sends through [transport]. */
private class MessagingHost(
    buckets: com.typewritermc.services.libs.communicator.kv.KeyValueBuckets,
    transport: com.typewritermc.services.libs.communicator.transport.MessageTransport,
) : HostedRuntimeHost {
    private val telemetry =
        io.opentelemetry.api.OpenTelemetry
            .noop()
    override val messaging =
        kotlinx.coroutines.flow.MutableStateFlow<com.typewritermc.loader.api.HostedMessagingSession?>(
            com.typewritermc.loader.api.HostedMessagingSession(
                id = 1,
                organizationId = "organization",
                communicator =
                    com.typewritermc.services.libs.communicator.client.Communicator(
                        transport,
                        telemetry.serviceTelemetry("engine test"),
                        io.opentelemetry.context.propagation.ContextPropagators
                            .noop(),
                    ),
                buckets = buckets,
            ),
        )
    override val openTelemetry get() = telemetry
    override val sharedArtifacts get() = error("Wiring never reaches shared artifacts.")
}
