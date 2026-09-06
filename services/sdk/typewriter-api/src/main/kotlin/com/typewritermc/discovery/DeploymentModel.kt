package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.TypeCatalog
import kotlinx.serialization.Serializable

/**
 * Supplies deployment specific inputs to registrars and availability expressions.
 *
 * Keys must be nonblank. Values remain open strings so hosts can publish facts without extending the SDK. These
 * facts describe the selected deployment; they are not a live configuration subscription.
 */
@Serializable
data class DeploymentFacts(
    val values: Map<String, String> = emptyMap(),
) {
    init {
        require(values.keys.none(String::isBlank)) { "Deployment fact keys must not be blank." }
    }
}

/**
 * Records whether an artifact or source part can participate in the selected deployment.
 *
 * Ineligible entries retain concrete reasons for catalog consumers instead of disappearing from discovery.
 */
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

/**
 * Identifies one catalog snapshot for invalidation and consistency checks.
 *
 * The value is an opaque nonblank token. Consumers compare equality; no chronological ordering is defined.
 */
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

/**
 * Explains a discovery problem, optionally attributed to a particular contribution.
 *
 * Code and message must be nonblank. The contribution key lets callers locate the artifact and source part
 * responsible.
 */
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

/**
 * Collects the catalog metadata and diagnostics for one deployment generation.
 *
 * Artifact and source part eligibility explain unavailable contributions. The type catalog describes structure;
 * executable bindings and loaded runtime resources are managed separately.
 */
@Serializable
data class DeploymentDiscoverySnapshot(
    val generation: CatalogGeneration,
    val artifacts: List<ArtifactCatalogEntry>,
    val sourceParts: List<SourcePartCatalogEntry>,
    val types: TypeCatalog,
    val diagnostics: List<DiscoveryDiagnostic>,
)
