package com.typewritermc.discovery

import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.ContributionKey
import skirout.editor.v1.type_catalog.ContributionName as SkirContributionName
import skirout.editor.v1.type_catalog.ContributionSourceId as SkirContributionSourceId
import skirout.editor.v1.type_catalog.ProducerId as SkirProducerId

private val SEGMENT_PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.]*")

@JvmInline
@Serializable
value class DiscoveryDomainId(
    val value: String,
) {
    init {
        require(value.matches(SEGMENT_PATTERN)) { "Discovery domain ids must be safe path segments." }
    }
}

object DiscoveryDomains {
    val Realm = DiscoveryDomainId("realm")
    val Execution = DiscoveryDomainId("execution")
}

/** The key of one contribution, built from the imprint ids, which check their own syntax. */
fun contributionKey(
    source: ContributionSourceId,
    sourcePart: String,
    producer: ProducerId,
    name: ContributionName,
): ContributionKey =
    ContributionKey(
        source = SkirContributionSourceId(value = source.value),
        sourcePart = sourcePart,
        producer = SkirProducerId(value = producer.value),
        name = SkirContributionName(value = name.value),
    )
