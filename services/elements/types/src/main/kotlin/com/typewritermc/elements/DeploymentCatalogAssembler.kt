package com.typewritermc.elements

import com.typewritermc.discovery.ArtifactCatalogEntry
import com.typewritermc.discovery.AssembledTypeDiscovery
import com.typewritermc.discovery.CatalogGeneration
import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DeploymentSelection
import com.typewritermc.discovery.DiscoveryDiagnostic
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.SourcePartEligibilityResolver
import com.typewritermc.discovery.TypeContributionAssembler
import com.typewritermc.discovery.runtime.ManifestDiscoveryReader
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.GeneratedContribution

data class AssembledDeploymentCatalog(
    val discovery: DeploymentDiscoverySnapshot,
    val elements: ElementCatalog,
    val runtimeDiscovery: AssembledTypeDiscovery,
    val unknownContributions: List<GeneratedContribution>,
)

object DeploymentCatalogAssembler {
    fun assemble(
        generation: CatalogGeneration,
        engine: EngineManifest,
        extensions: Collection<ExtensionManifest>,
        selectedExtensions: Set<ArtifactId>,
        facts: DeploymentFacts,
    ): AssembledDeploymentCatalog {
        val orderedExtensions = extensions.sortedBy { it.id.value }
        val selection = DeploymentSelection(engine, selectedExtensions)
        val sourceParts = SourcePartEligibilityResolver.resolve(selection, orderedExtensions)
        val manifests = listOf(engine) + orderedExtensions
        val read = ManifestDiscoveryReader.read(manifests)
        val runtimeDiscovery = TypeContributionAssembler.assemble(read.types, sourceParts)
        val elements =
            ElementCatalogAssembler.assemble(
                ElementContributionReader.read(manifests),
                sourceParts,
                facts,
            )
        val artifacts =
            buildList {
                add(ArtifactCatalogEntry(engine.id, Eligibility.Eligible))
                engine.resolvedCapabilities
                    .sortedBy { it.id.value }
                    .forEach { add(ArtifactCatalogEntry(it.id, Eligibility.Eligible)) }
                orderedExtensions.forEach { extension ->
                    val eligibility =
                        if (extension.id in selectedExtensions) {
                            Eligibility.Eligible
                        } else {
                            Eligibility.Ineligible(listOf("Extension ${extension.id} is not selected."))
                        }
                    add(ArtifactCatalogEntry(extension.id, eligibility))
                }
            }.distinctBy(ArtifactCatalogEntry::id)
        val snapshot =
            DeploymentDiscoverySnapshot(
                generation = generation,
                artifacts = artifacts,
                sourceParts = sourceParts,
                types = runtimeDiscovery.catalog,
                diagnostics = emptyList<DiscoveryDiagnostic>(),
            )
        return AssembledDeploymentCatalog(snapshot, elements, runtimeDiscovery, read.unknown)
    }
}
