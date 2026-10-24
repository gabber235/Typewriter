package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.ContributionKey

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

data class DiscoveryDiagnostic(
    val code: String,
    val message: String,
    val contribution: ContributionKey? = null,
)
