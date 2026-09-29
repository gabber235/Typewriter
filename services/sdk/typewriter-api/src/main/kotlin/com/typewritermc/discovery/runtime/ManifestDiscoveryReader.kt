package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.KeyedTypeContribution
import com.typewritermc.discovery.TYPE_DISCOVERY_PRODUCER
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.ImprintManifest

/** One logical contribution and every artifact that contains its identical payload. */
data class CarriedContribution(
    val contribution: GeneratedContribution,
    val carriers: Set<ArtifactId>,
)

/**
 * Separates decoded type contributions from payloads owned by unknown producers.
 *
 * Unknown payloads remain intact so another reader can process them without requiring this SDK to understand their
 * schema.
 */
data class ReadDiscoveryContributions(
    val types: List<KeyedTypeContribution>,
    val unknown: List<CarriedContribution>,
)

/**
 * Reads known type payloads from manifests without loading artifact classes.
 *
 * Equal copies of a logical contribution are decoded once while every physical carrier remains known. Different
 * payloads under one key fail with both carrier identities. Results follow deterministic contribution order.
 */
object ManifestDiscoveryReader {
    /**
     * Decodes type contributions and preserves payloads from producers this SDK does not recognize.
     *
     * Conflicting copies fail before decoding. Known payload failures include the logical source key in the
     * thrown cause, while result lists use stable contribution key order.
     */
    fun read(manifests: Collection<ImprintManifest>): ReadDiscoveryContributions {
        val typeContributions = mutableListOf<KeyedTypeContribution>()
        val unknown = mutableListOf<CarriedContribution>()
        val copiesByKey =
            manifests
                .flatMap { manifest -> manifest.contributions.map { contribution -> contribution to manifest.id } }
                .groupBy { (contribution, _) -> contribution.key() }
        copiesByKey.entries.sortedBy { it.key.sortKey() }.forEach { (key, copies) ->
            val contribution = copies.first().first
            val carriers = copies.mapTo(linkedSetOf()) { it.second }
            require(carriers.size == copies.size) { "Duplicate discovery contribution $key in one artifact." }
            require(copies.all { (copy, _) -> copy.payload.contentEquals(contribution.payload) }) {
                "Conflicting discovery contribution $key in artifacts ${carriers.joinToString { it.value }}."
            }
            when (contribution.producer) {
                TYPE_DISCOVERY_PRODUCER -> {
                    typeContributions +=
                        KeyedTypeContribution(
                            key = key,
                            carriers = carriers,
                            contribution = decode(contribution) { TypeDiscoveryContributionCodec.decode(it) },
                        )
                }

                else -> {
                    unknown += CarriedContribution(contribution, carriers)
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

private fun GeneratedContribution.key(): ContributionKey = ContributionKey(source, sourcePart, producer, name)

private fun ContributionKey.sortKey(): String = "${source.value}/$sourcePart/${producer.value}/${name.value}"
