package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.TypeCatalog
import kotlinx.serialization.Serializable

@Serializable
data class DeploymentFacts(
    val values: Map<String, String> = emptyMap(),
) {
    init {
        require(values.keys.none(String::isBlank)) { "Deployment fact keys must not be blank." }
    }
}

@Serializable
sealed interface Eligibility {
    @Serializable
    data object Eligible : Eligibility

    @Serializable
    data class Ineligible(
        val reasons: List<String>,
    ) : Eligibility {
        init {
            require(reasons.isNotEmpty() && reasons.none(String::isBlank)) {
                "Ineligible catalog items require concrete reasons."
            }
        }
    }
}

@JvmInline
@Serializable
value class CatalogGeneration(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Catalog generations must not be blank." }
    }
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
) {
    init {
        require(code.isNotBlank()) { "Discovery diagnostic codes must not be blank." }
        require(message.isNotBlank()) { "Discovery diagnostic messages must not be blank." }
    }
}

@Serializable
data class DeploymentDiscoverySnapshot(
    val generation: CatalogGeneration,
    val artifacts: List<ArtifactCatalogEntry>,
    val sourceParts: List<SourcePartCatalogEntry>,
    val types: TypeCatalog,
    val diagnostics: List<DiscoveryDiagnostic>,
)
