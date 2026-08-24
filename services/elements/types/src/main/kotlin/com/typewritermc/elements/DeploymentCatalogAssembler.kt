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
import com.typewritermc.imprint.ImprintManifest

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
        return assemble(generation, listOf(engine), orderedExtensions, sourceParts, facts)
    }

    fun assemble(
        generation: CatalogGeneration,
        engines: Collection<EngineManifest>,
        extensions: Collection<ExtensionManifest>,
        sourceParts: Collection<com.typewritermc.discovery.SourcePartCatalogEntry>,
        facts: DeploymentFacts,
        otherManifests: Collection<ImprintManifest> = emptyList(),
    ): AssembledDeploymentCatalog {
        val orderedEngines = engines.sortedBy { it.id.value }
        val orderedExtensions = extensions.sortedBy { it.id.value }
        val manifests = otherManifests.sortedBy { it.id.value } + orderedEngines + orderedExtensions
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
                otherManifests.sortedBy { it.id.value }.forEach { add(ArtifactCatalogEntry(it.id, Eligibility.Eligible)) }
                orderedEngines.forEach { engine ->
                    add(ArtifactCatalogEntry(engine.id, Eligibility.Eligible))
                    engine.resolvedCapabilities
                        .sortedBy { it.id.value }
                        .forEach { add(ArtifactCatalogEntry(it.id, Eligibility.Eligible)) }
                }
                orderedExtensions.forEach { extension ->
                    val eligibility =
                        if (sourceParts.any { it.artifact == extension.id && it.eligibility is Eligibility.Eligible }) {
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
                sourceParts = sourceParts.toList(),
                types = runtimeDiscovery.catalog,
                diagnostics = emptyList<DiscoveryDiagnostic>(),
            )
        return AssembledDeploymentCatalog(snapshot, elements, runtimeDiscovery, read.unknown)
    }
}
