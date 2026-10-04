package com.typewritermc.discovery

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import kotlinx.serialization.Serializable

@Serializable
data class DeploymentFacts(
    val values: Map<String, String> = emptyMap(),
)

@Serializable
sealed interface Eligibility {
    @Serializable data object Eligible : Eligibility

    @Serializable data class Ineligible(
        val reasons: List<String>,
    ) : Eligibility
}

@Serializable
data class ArtifactCatalogEntry(
    val id: ArtifactId,
    val eligibility: Eligibility,
)

@Serializable
data class SourcePartCatalogEntry(
    val artifact: ArtifactId,
    val sourcePart: String,
    val eligibility: Eligibility,
)

@Serializable
data class DiscoveryDiagnostic(
    val code: String,
    val message: String,
    val contribution: ContributionKey? = null,
)

data class DeploymentDiscoverySnapshot(
    val generation: CatalogGeneration,
    val artifacts: List<ArtifactCatalogEntry>,
    val sourceParts: List<SourcePartCatalogEntry>,
    val catalog: EditorCatalogSnapshot,
    val diagnostics: List<DiscoveryDiagnostic>,
)
