package com.typewritermc.discovery

import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import kotlinx.serialization.Serializable

private val SEGMENT_PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.]*")
private val QUALIFIED_CLASS_PATTERN = Regex("[A-Za-z_$][A-Za-z0-9_$]*(\\.[A-Za-z_$][A-Za-z0-9_$]*)+")

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
data class ExecutableBinding(
    val localName: String,
    val domain: DiscoveryDomainId,
    val moduleProviderClass: String,
) {
    init {
        require(localName.matches(SEGMENT_PATTERN)) { "Executable binding names must be safe path segments." }
        require(moduleProviderClass.matches(QUALIFIED_CLASS_PATTERN)) { "Module provider classes must use qualified JVM names." }
    }
}

@Serializable
enum class GraphDirection {
    LEFT_TO_RIGHT,
    RIGHT_TO_LEFT,
    TOP_TO_BOTTOM,
    BOTTOM_TO_TOP,
}
