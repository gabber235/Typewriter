package com.typewritermc.discovery

import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import kotlinx.serialization.Serializable

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

@Serializable
data class ContributionKey(
    val source: ContributionSourceId,
    val sourcePart: String,
    val producer: ProducerId,
    val name: ContributionName,
)

@Serializable
enum class GraphDirection {
    LEFT_TO_RIGHT,
    RIGHT_TO_LEFT,
    TOP_TO_BOTTOM,
    BOTTOM_TO_TOP,
}
