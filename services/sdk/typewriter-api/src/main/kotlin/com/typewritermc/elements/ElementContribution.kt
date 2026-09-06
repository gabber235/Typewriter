package com.typewritermc.elements

import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.ContributionName
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomainId
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
 * Names the provider that attaches behavior to an element in a discovery domain.
 *
 * The class name remains manifest metadata until runtime loading.
 */
@Serializable
data class ElementFacetBinding(
    val elementType: ElementTypeId,
    val domain: DiscoveryDomainId,
    val providerClass: String,
)

/**
 * Carries generated element descriptors and facet bindings in a versioned manifest payload.
 *
 * Construction rejects unknown schema versions and duplicate descriptor identities within the contribution.
 * Deployment assembly checks uniqueness across artifacts.
 */
@Serializable
data class ElementDiscoveryContribution(
    val schema: String = ELEMENT_DISCOVERY_SCHEMA,
    val version: Int = ELEMENT_DISCOVERY_VERSION,
    val descriptors: List<ElementDescriptor>,
    val facets: List<ElementFacetBinding>,
) {
    init {
        require(schema == ELEMENT_DISCOVERY_SCHEMA) { "Unsupported element discovery schema $schema." }
        require(version == ELEMENT_DISCOVERY_VERSION) { "Unsupported element discovery version $version." }
        require(descriptors.map(ElementDescriptor::id).distinct().size == descriptors.size) {
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
data class ElementCatalogEntry(
    val origin: ArtifactId,
    val sourcePart: String,
    val descriptor: ElementDescriptor,
    val eligible: Boolean,
    val available: Boolean,
    val ineligibilityReasons: List<String> = emptyList(),
) {
    init {
        require(eligible || ineligibilityReasons.isNotEmpty()) { "Ineligible elements require concrete reasons." }
    }
}

data class KeyedElementContribution(
    val key: ContributionKey,
    val contribution: ElementDiscoveryContribution,
)

/**
 * Decodes element payloads from manifests in stable origin order.
 *
 * Other producers are ignored. Duplicate element contribution keys and malformed known payloads fail with
 * contribution context.
 */
object ElementContributionReader {
    fun read(manifests: Collection<ImprintManifest>): List<KeyedElementContribution> =
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
                KeyedElementContribution(
                    key,
                    runCatching { ElementDiscoveryContributionCodec.decode(generated.payload) }
                        .getOrElse { throw IllegalArgumentException("Malformed known contribution $key.", it) },
                )
            }.also { contributions ->
                require(contributions.map(KeyedElementContribution::key).distinct().size == contributions.size) {
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
object ElementCatalogAssembler {
    fun assemble(
        contributions: Collection<KeyedElementContribution>,
        sourceParts: Collection<SourcePartCatalogEntry>,
        facts: DeploymentFacts = DeploymentFacts(),
    ): ElementCatalog {
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
                        ElementCatalogEntry(
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
        return ElementCatalog(entries)
    }
}

/**
 * Indexes the element schemas visible in a deployment, including unavailable entries.
 *
 * Element identities must be unique. [descriptor] matches an exact resolved type reference and does not filter
 * eligibility or availability.
 */
@Serializable
data class ElementCatalog(
    val entries: List<ElementCatalogEntry>,
) {
    init {
        require(entries.map { it.descriptor.id }.distinct().size == entries.size) {
            "Element catalog ids must be unique."
        }
    }

    fun descriptor(type: ResolvedTypeRef): ElementDescriptor? = entries.singleOrNull { it.descriptor.type == type }?.descriptor
}

/**
 * Serializes versioned element discovery payloads as CBOR with defaults included.
 *
 * Decode failures propagate to the manifest reader, which supplies origin context.
 */
@OptIn(ExperimentalSerializationApi::class)
object ElementDiscoveryContributionCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(contribution: ElementDiscoveryContribution): ByteArray = cbor.encodeToByteArray(contribution)

    fun decode(payload: ByteArray): ElementDiscoveryContribution = cbor.decodeFromByteArray(payload)
}

const val ELEMENT_DISCOVERY_SCHEMA = "typewriter.elements"
const val ELEMENT_DISCOVERY_VERSION = 1
const val ELEMENT_DISCOVERY_PRODUCER = "elements"
