package com.typewritermc.engine.runtime

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.COMMON_SOURCE_PART
import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.StagedHostedRuntime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel

@ImprintRuntimeEntrypoint
class EngineDeploymentEntrypoint : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime {
        val implementation = requireNotNull(context.engineImplementation) { "Engine runtime implementation is missing." }
        require(implementation.placement == context.identity.placement) {
            "Engine runtime implementation placement does not match the hosted runtime."
        }
        val artifacts =
            listOf(
                GeneratedProviderArtifact(
                    artifact = context.artifacts.runtimeArtifact.manifest.id,
                    path = context.artifacts.runtimeArtifact.path,
                ),
            ) +
                context.artifacts.extensions.mapNotNull { extension ->
                    val acceptedParts =
                        extension.sourceParts.mapNotNullTo(linkedSetOf()) { sourcePart ->
                            val eligible = sourcePart.disposition as? SourcePartDisposition.Eligible
                            sourcePart.name.takeIf { eligible != null && context.identity.placement in eligible.placements }
                        }
                    acceptedParts.takeIf(Set<String>::isNotEmpty)?.let {
                        GeneratedProviderArtifact(
                            artifact = extension.id,
                            path = extension.path,
                            acceptedSourceParts = it + COMMON_SOURCE_PART,
                        )
                    }
                }
        val deployment =
            GeneratedProviderLoader().load(
                artifacts = artifacts,
                facts = DeploymentFacts(context.facts),
                domain = DiscoveryDomains.Execution,
                acceptedKinds = EXECUTION_PROVIDER_KINDS,
                parentClassLoader = requireNotNull(javaClass.classLoader),
            )
        val deploymentScope = CoroutineScope(Dispatchers.Default)
        return try {
            val assembly =
                deployment.providers.contributions.assemble(
                    CatalogAssemblyContext(CatalogGeneration(executionCatalogIdentity(artifacts))),
                )
            val runtime =
                ReloadableEngineRuntime(
                    deployment = deployment,
                    registrars = deployment.providers.registrars.map { it.registrar },
                    parentScope = deploymentScope,
                    implementationToken = implementation.fingerprint(),
                    enforceImplementationCompatibility =
                        context.identity.placement == RuntimePlacement.PRIMARY_ENGINE,
                    contentGateway = PageContentGateway(assembly.checked, assembly.bindings, assembly.snapshot.relations),
                    contentDelivery = MessagingEngineContentDelivery(context.host, context.identity.realmId, deploymentScope),
                )
            ScopedEngineRuntime(runtime, deploymentScope)
        } catch (failure: Throwable) {
            deploymentScope.cancel()
            runCatching { deployment.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}

/** Owns the coroutine scope of one staged engine deployment and cancels it after final closure. */
private class ScopedEngineRuntime(
    private val runtime: ReloadableEngineRuntime,
    private val scope: CoroutineScope,
) : StagedHostedRuntime by runtime {
    override suspend fun close() {
        try {
            runtime.close()
        } finally {
            scope.cancel()
        }
    }
}

private fun executionCatalogIdentity(artifacts: List<GeneratedProviderArtifact>): String =
    artifacts.joinToString(separator = ",") { it.artifact.value }

private val EXECUTION_PROVIDER_KINDS =
    setOf(
        GeneratedProviderKind.Type,
        GeneratedProviderKind.NativeBinding,
        GeneratedProviderKind.Resource,
        GeneratedProviderKind.Relation,
        GeneratedProviderKind.EndpointBindings,
        GeneratedProviderKind.Registrar,
    )
