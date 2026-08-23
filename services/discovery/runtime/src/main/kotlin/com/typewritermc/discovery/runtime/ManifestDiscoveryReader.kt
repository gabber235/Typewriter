package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.ContributionName
import com.typewritermc.discovery.KeyedTypeContribution
import com.typewritermc.discovery.ProducerId
import com.typewritermc.discovery.TYPE_DISCOVERY_PRODUCER
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.ImprintManifest

data class ReadDiscoveryContributions(
    val types: List<KeyedTypeContribution>,
    val unknown: List<GeneratedContribution>,
)

object ManifestDiscoveryReader {
    fun read(manifests: Collection<ImprintManifest>): ReadDiscoveryContributions {
        val typeContributions = mutableListOf<KeyedTypeContribution>()
        val unknown = mutableListOf<GeneratedContribution>()
        val all = manifests.flatMap(ImprintManifest::contributions)
        val duplicateKeys = all.groupBy(GeneratedContribution::key).filterValues { it.size > 1 }
        require(duplicateKeys.isEmpty()) { "Duplicate discovery contribution keys: ${duplicateKeys.keys}." }

        all.sortedBy { it.key().sortKey() }.forEach { contribution ->
            when (contribution.producer) {
                TYPE_DISCOVERY_PRODUCER.value -> {
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

private fun GeneratedContribution.key(): ContributionKey = ContributionKey(origin, sourcePart, ProducerId(producer), ContributionName(name))

private fun ContributionKey.sortKey(): String = "${origin.value}/$sourcePart/${producer.value}/${name.value}"
