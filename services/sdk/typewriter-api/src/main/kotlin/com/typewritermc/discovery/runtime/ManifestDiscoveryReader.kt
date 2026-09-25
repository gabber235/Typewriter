package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.KeyedTypeContribution
import com.typewritermc.discovery.TYPE_DISCOVERY_PRODUCER
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.ImprintManifest

/**
 * Separates decoded type contributions from payloads owned by unknown producers.
 *
 * Unknown payloads remain intact so another reader can process them without requiring this SDK to understand their
 * schema.
 */
data class ReadDiscoveryContributions(
    val types: List<KeyedTypeContribution>,
    val unknown: List<GeneratedContribution>,
)

/**
 * Reads known type payloads from manifests without loading artifact classes.
 *
 * Duplicate contribution keys are rejected across all producers. Known malformed payloads fail with their origin
 * and cause; unknown producers are returned separately. Results follow deterministic contribution order.
 */
object ManifestDiscoveryReader {
    /**
     * Decodes type contributions and preserves payloads from producers this SDK does not recognize.
     *
     * Duplicate keys fail before decoding. Known payload failures include the full contribution origin in the
     * thrown cause, while result lists use stable contribution key order.
     */
    fun read(manifests: Collection<ImprintManifest>): ReadDiscoveryContributions {
        val typeContributions = mutableListOf<KeyedTypeContribution>()
        val unknown = mutableListOf<GeneratedContribution>()
        val all = manifests.flatMap(ImprintManifest::contributions)
        val duplicateKeys = all.groupBy(GeneratedContribution::key).filterValues { it.size > 1 }
        require(duplicateKeys.isEmpty()) { "Duplicate discovery contribution keys: ${duplicateKeys.keys}." }

        all.sortedBy { it.key().sortKey() }.forEach { contribution ->
            when (contribution.producer) {
                TYPE_DISCOVERY_PRODUCER -> {
                    typeContributions +=
                        KeyedTypeContribution(
                            contribution.key(),
                            decode(contribution) { TypeDiscoveryContributionCodec.decode(it) },
                        )
                }

                else -> {
                    unknown += contribution
                }
            }
        }
        return ReadDiscoveryContributions(typeContributions, unknown)
    }

    private fun <T> decode(
        contribution: GeneratedContribution,
        decoder: (ByteArray) -> T,
    ): T =
        runCatching { decoder(contribution.payload) }
            .getOrElse { failure ->
                throw IllegalArgumentException("Malformed known contribution ${contribution.key().sortKey()}.", failure)
            }
}

private fun GeneratedContribution.key(): ContributionKey = ContributionKey(origin, sourcePart, producer, name)

private fun ContributionKey.sortKey(): String = "${origin.value}/$sourcePart/${producer.value}/${name.value}"
