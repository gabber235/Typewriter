package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.SourcePartCatalogEntry
import com.typewritermc.discovery.TypeContributionAssembler
import com.typewritermc.discovery.runtime.DiscoveryArtifactPackage
import com.typewritermc.discovery.runtime.DiscoveryModuleLoader
import com.typewritermc.discovery.runtime.ManifestDiscoveryReader
import com.typewritermc.discovery.runtime.RuntimeRegistrar
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedRuntimeProvider
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.StagedHostedRuntime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import java.nio.file.Path
import java.util.zip.ZipFile

class EngineDeploymentEntrypoint : HostedRuntimeProvider {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime {
        val artifactPaths = listOf(context.artifacts.runtimeArtifact) + context.artifacts.extensions.map { it.path }
        val manifests = artifactPaths.map(::readManifest)
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
        val artifactPackage =
            DiscoveryArtifactPackage(
                artifacts = artifactPaths.map { it.toUri().toURL() },
                selectedEngine = engine.id,
                selectedExtensions = extensions.mapTo(mutableSetOf()) { it.id },
                facts = DeploymentFacts(context.facts),
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
            )
        } catch (failure: Throwable) {
            parentScope.cancel()
            runCatching { deployment.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }
}

private fun readManifest(path: Path): ImprintManifest =
    ZipFile(path.toFile()).use { archive ->
        val entry =
            requireNotNull(archive.getEntry(IMPRINT_MANIFEST_PATH)) {
                "Hosted artifact ${path.fileName} does not contain an Imprint manifest."
            }
        ImprintManifestCodec.decode(archive.getInputStream(entry).readBytes())
    }
