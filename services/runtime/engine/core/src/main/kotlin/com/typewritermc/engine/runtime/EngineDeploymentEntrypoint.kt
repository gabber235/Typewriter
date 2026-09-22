package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.SourcePartCatalogEntry
import com.typewritermc.discovery.TypeContributionAssembler
import com.typewritermc.discovery.runtime.DiscoveryArtifactPackage
import com.typewritermc.discovery.runtime.DiscoveryModuleLoader
import com.typewritermc.discovery.runtime.ManifestDiscoveryReader
import com.typewritermc.elements.ElementCatalogAssembler
import com.typewritermc.elements.ElementContributionReader
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.StagedHostedRuntime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel

/**
 * Stages an engine from loader supplied manifests and loads execution discovery into an isolated deployment.
 *
 * The package must contain one engine plus extensions. Staging constructs the content gateway and delivery adapter
 * but registration starts on activation. Failure during runtime construction cancels its parent scope and closes
 * discovery resources.
 */
@ImprintRuntimeEntrypoint
class EngineDeploymentEntrypoint : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime {
        val artifactFiles =
            listOf(context.artifacts.runtimeArtifact) +
                context.artifacts.extensions.map { HostedArtifact(it.path, it.manifest) }
        val artifactPaths = artifactFiles.map { it.path }
        val manifests = artifactFiles.map { it.manifest }
        val engine = manifests.filterIsInstance<EngineManifest>().single()
        val extensions = manifests.filterIsInstance<ExtensionManifest>()
        require(manifests.size == 1 + extensions.size) {
            "An engine deployment may contain one engine and extension artifacts."
        }
        val contributions = ManifestDiscoveryReader.read(manifests)
        val sourceParts =
            context.artifacts.extensions.flatMap { extension ->
                extension.sourceParts.map { sourcePart ->
                    SourcePartCatalogEntry(
                        extension.id,
                        sourcePart.name,
                        when (val disposition = sourcePart.disposition) {
                            is SourcePartDisposition.Eligible -> Eligibility.Eligible
                            is SourcePartDisposition.Ineligible -> Eligibility.Ineligible(disposition.reasons)
                        },
                    )
                }
            }
        val discovery = TypeContributionAssembler.assemble(contributions.types, sourceParts)
        val facts = DeploymentFacts(context.facts)
        val elementCatalog =
            ElementCatalogAssembler.assemble(
                ElementContributionReader.read(manifests),
                sourceParts,
                facts,
            )
        val artifactPackage =
            DiscoveryArtifactPackage(
                artifacts = artifactPaths.map { it.toUri().toURL() },
                selectedEngine = engine.id,
                selectedExtensions = extensions.mapTo(mutableSetOf()) { it.id },
                facts = facts,
            )
        val deployment =
            DiscoveryModuleLoader().load(
                artifactPackage,
                DiscoveryDomains.Execution,
                discovery,
                requireNotNull(javaClass.classLoader),
            )
        val parentScope = CoroutineScope(Dispatchers.Default)
        return try {
            ReloadableEngineRuntime(
                deployment = deployment,
                registrars = deployment.application.koin.getAll<RuntimeRegistrar>(),
                parentScope = parentScope,
                contentGateway =
                    AssemblingEngineContentGateway(
                        listOf(PageCompiledArtifactConsumer(elementCatalog, deployment.prototypes)),
                    ),
                contentDelivery = MessagingEngineContentDelivery(context.host, context.identity.realmId, parentScope),
            )
        } catch (failure: Throwable) {
            parentScope.cancel()
            runCatching { deployment.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}
