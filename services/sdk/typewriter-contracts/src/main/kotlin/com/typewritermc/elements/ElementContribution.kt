package com.typewritermc.elements

import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.ContributionName
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.ProducerId
import com.typewritermc.discovery.SourcePartCatalogEntry
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.types.ResolvedTypeRef
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

/**
 * Carries generated element descriptors in a versioned manifest payload.
 *
 * Construction rejects unknown schema versions and duplicate descriptor identities within the contribution.
 * Deployment assembly checks uniqueness across artifacts.
 */
@Serializable
data class ContentDiscoveryContribution(
    val schema: String = ELEMENT_DISCOVERY_SCHEMA,
    val version: Int = ELEMENT_DISCOVERY_VERSION,
    val descriptors: List<ContentDescriptor>,
) {
    init {
        require(schema == ELEMENT_DISCOVERY_SCHEMA) { "Unsupported element discovery schema $schema." }
        require(version == ELEMENT_DISCOVERY_VERSION) { "Unsupported element discovery version $version." }
        require(descriptors.map(ContentDescriptor::id).distinct().size == descriptors.size) {
            "An element contribution cannot contain duplicate descriptors."
        }
    }
}

/**
 * Keeps an element descriptor visible together with its deployment constraints.
 *
 * [eligible] reflects source part selection and requires reasons when false. [available] is evaluated
 * independently against deployment facts; consumers must consider both before offering an element.
 */
@Serializable
data class ContentCatalogEntry(
    val origin: ArtifactId,
    val sourcePart: String,
    val descriptor: ContentDescriptor,
    val eligible: Boolean,
    val available: Boolean,
    val ineligibilityReasons: List<String> = emptyList(),
) {
    init {
        require(eligible || ineligibilityReasons.isNotEmpty()) { "Ineligible elements require concrete reasons." }
    }
}

data class KeyedContentContribution(
    /** Manifest identity used to distinguish contributions from the same artifact. */
    val key: ContributionKey,
    /** Decoded element descriptors for [key]. */
    val contribution: ContentDiscoveryContribution,
)

/**
 * Decodes element payloads from manifests in stable origin order.
 *
 * Other producers are ignored. Duplicate element contribution keys and malformed known payloads fail with
 * contribution context.
 */
object ContentContributionReader {
    /** Reads known contributions and preserves their manifest provenance for catalog assembly. */
    fun read(manifests: Collection<ImprintManifest>): List<KeyedContentContribution> =
        manifests
            .flatMap(ImprintManifest::contributions)
            .filter { it.producer == ELEMENT_DISCOVERY_PRODUCER }
            .sortedBy { "${it.origin.value}/${it.sourcePart}/${it.name}" }
            .map { generated ->
                val key =
                    ContributionKey(
                        generated.origin,
                        generated.sourcePart,
                        ProducerId(generated.producer),
                        ContributionName(generated.name),
                    )
                KeyedContentContribution(
                    key,
                    runCatching { ContentDiscoveryContributionCodec.decode(generated.payload) }
                        .getOrElse { throw IllegalArgumentException("Malformed known contribution $key.", it) },
                )
            }.also { contributions ->
                require(contributions.map(KeyedContentContribution::key).distinct().size == contributions.size) {
                    "Element discovery contribution keys must be unique."
                }
            }
}

/**
 * Builds the deployment element catalog while retaining ineligible descriptors.
 *
 * Missing source part eligibility is treated as ineligible. Availability is evaluated against facts, entries are
 * sorted by identity, and duplicate element identities across the deployment are rejected.
 */
object ContentCatalogAssembler {
    /** Combines generated contributions with source part eligibility and deployment facts. */
    fun assemble(
        contributions: Collection<KeyedContentContribution>,
        sourceParts: Collection<SourcePartCatalogEntry>,
        facts: DeploymentFacts = DeploymentFacts(),
    ): ContentCatalog {
        val eligibility = sourceParts.associateBy { it.artifact to it.sourcePart }
        val entries =
            contributions
                .flatMap { keyed ->
                    keyed.contribution.descriptors.map { descriptor ->
                        val sourceEligibility = eligibility[keyed.key.origin to keyed.key.sourcePart]
                        val reasons =
                            when (val value = sourceEligibility?.eligibility) {
                                Eligibility.Eligible -> emptyList()
                                is Eligibility.Ineligible -> value.reasons
                                null -> listOf("Source part eligibility is unavailable.")
                            }
                        ContentCatalogEntry(
                            origin = keyed.key.origin,
                            sourcePart = keyed.key.sourcePart,
                            descriptor = descriptor,
                            eligible = reasons.isEmpty(),
                            available = descriptor.isAvailable(facts),
                            ineligibilityReasons = reasons,
                        )
                    }
                }.sortedBy {
                    it.descriptor.id.value
                        .toString()
                }
        val duplicates = entries.groupBy { it.descriptor.id }.filterValues { it.size > 1 }
        require(duplicates.isEmpty()) { "Element ids must be unique across the deployment: ${duplicates.keys}." }
        return ContentCatalog(entries)
    }
}

/**
 * Indexes the element schemas visible in a deployment, including unavailable entries.
 *
 * Element identities must be unique. [descriptor] matches an exact resolved type reference and does not filter
 * eligibility or availability.
 */
@Serializable
data class ContentCatalog(
    val entries: List<ContentCatalogEntry>,
) {
    init {
        require(entries.map { it.descriptor.id }.distinct().size == entries.size) {
            "Element catalog ids must be unique."
        }
    }

    /** Finds the descriptor whose structural type exactly matches [type], if one exists. */
    fun descriptor(type: ResolvedTypeRef): ContentDescriptor? = entries.singleOrNull { it.descriptor.type == type }?.descriptor
}

/**
 * Serializes versioned element discovery payloads as CBOR with defaults included.
 *
 * Decode failures propagate to the manifest reader, which supplies origin context.
 */
@OptIn(ExperimentalSerializationApi::class)
object ContentDiscoveryContributionCodec {
    private val cbor = Cbor { encodeDefaults = true }

    /** Encodes a contribution for the manifest contribution payload. */
    fun encode(contribution: ContentDiscoveryContribution): ByteArray = cbor.encodeToByteArray(contribution)

    /** Decodes one manifest contribution payload, rejecting malformed or unsupported data. */
    fun decode(payload: ByteArray): ContentDiscoveryContribution = cbor.decodeFromByteArray(payload)
}

/** Schema identifier for generated element discovery contributions. */
const val ELEMENT_DISCOVERY_SCHEMA = "typewriter.elements"

/** Current encoded shape version for [ELEMENT_DISCOVERY_SCHEMA]. */
const val ELEMENT_DISCOVERY_VERSION = 1

/** Manifest producer name used to select element discovery contributions. */
const val ELEMENT_DISCOVERY_PRODUCER = "elements"
