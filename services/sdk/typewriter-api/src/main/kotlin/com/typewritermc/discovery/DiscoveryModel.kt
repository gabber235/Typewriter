package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import kotlinx.serialization.Serializable

private val SEGMENT_PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.]*")
private val QUALIFIED_CLASS_PATTERN = Regex("[A-Za-z_$][A-Za-z0-9_$]*(\\.[A-Za-z_$][A-Za-z0-9_$]*)+")

/**
 * Selects the environment in which an executable contribution may load.
 *
 * Identifiers must be safe path segments. Runtime loading currently recognizes the Realm and Execution domains in
 * [DiscoveryDomains].
 */
@JvmInline
@Serializable
value class DiscoveryDomainId(
    val value: String,
) {
    init {
        require(value.matches(SEGMENT_PATTERN)) { "Discovery domain ids must be safe path segments." }
    }
}

/**
 * Defines the Realm and Execution discovery boundaries used when filtering generated modules and prototypes.
 */
object DiscoveryDomains {
    val Realm = DiscoveryDomainId("realm")
    val Execution = DiscoveryDomainId("execution")
}

/**
 * Identifies the generator responsible for a discovery payload.
 *
 * The reader uses this safe path segment to choose a codec; unknown producers can be retained without decoding
 * their payloads.
 */
@JvmInline
@Serializable
value class ProducerId(
    val value: String,
) {
    init {
        require(value.matches(SEGMENT_PATTERN)) { "Producer ids must be safe path segments." }
    }
}

/**
 * Names a contribution within its producer using a safe relative path.
 *
 * Each slash separated segment must match the discovery segment grammar; blank names and empty segments are
 * rejected.
 */
@JvmInline
@Serializable
value class ContributionName(
    val value: String,
) {
    init {
        require(value.isNotBlank() && value.split('/').all(SEGMENT_PATTERN::matches)) {
            "Contribution names must be safe relative paths."
        }
    }
}

/**
 * Identifies a contribution across artifacts, source parts, and generators.
 *
 * Use the complete key for deduplication and diagnostics. A local contribution name alone is not globally unique.
 */
@Serializable
data class ContributionKey(
    val origin: ArtifactId,
    val sourcePart: String,
    val producer: ProducerId,
    val name: ContributionName,
)

/**
 * Points discovery at a generated module provider for one runtime domain.
 *
 * The provider class is stored as a qualified JVM name so manifests can be inspected without loading executable
 * code. The runtime loader expects a public zero argument constructor and a generated discovery module
 * implementation.
 */
@Serializable
data class ExecutableBinding(
    val localName: String,
    val domain: DiscoveryDomainId,
    val moduleProviderClass: String,
) {
    init {
        require(localName.matches(SEGMENT_PATTERN)) { "Executable binding names must be safe path segments." }
        require(moduleProviderClass.isQualifiedClassName()) { "Module provider classes must use qualified JVM names." }
    }
}

/**
 * Connects a resolved structural type to its runtime codec provider in the listed domains.
 *
 * Class names remain metadata until runtime loading. At load time the returned prototype must match [type]; a
 * structurally similar codec is not interchangeable.
 */
@Serializable
data class PrototypeBinding(
    val type: ResolvedTypeRef,
    val runtimeClass: String,
    val prototypeProviderClass: String,
    val domains: Set<DiscoveryDomainId>,
) {
    init {
        require(runtimeClass.isQualifiedClassName()) { "Prototype runtime classes must use qualified JVM names." }
        require(prototypeProviderClass.isQualifiedClassName()) { "Prototype providers must use qualified JVM names." }
        require(domains.isNotEmpty()) { "Prototype bindings require at least one discovery domain." }
    }
}

/**
 * Carries generated structural definitions and optional executable bindings inside an Imprint contribution.
 *
 * Construction rejects unsupported schema versions and repeated definition or prototype identities. Deployment
 * assembly performs the additional conflict checks across contributions.
 */
@Serializable
data class TypeDiscoveryContribution(
    val schema: String = TYPE_DISCOVERY_SCHEMA,
    val version: Int = TYPE_DISCOVERY_VERSION,
    val definitions: List<TypeDefinition>,
    val prototypeBindings: List<PrototypeBinding>,
    val executableBindings: List<ExecutableBinding>,
) {
    init {
        require(schema == TYPE_DISCOVERY_SCHEMA) { "Unsupported type discovery schema $schema." }
        require(version == TYPE_DISCOVERY_VERSION) { "Unsupported type discovery version $version." }
        require(definitions.map(TypeDefinition::id).distinct().size == definitions.size) {
            "A type discovery contribution cannot contain duplicate definitions."
        }
        require(prototypeBindings.map(PrototypeBinding::type).distinct().size == prototypeBindings.size) {
            "A type discovery contribution cannot contain duplicate prototype bindings."
        }
    }
}

const val TYPE_DISCOVERY_SCHEMA = "typewriter.types"
const val TYPE_DISCOVERY_VERSION = 1
val TYPE_DISCOVERY_PRODUCER = ProducerId("types")

private fun String.isQualifiedClassName(): Boolean = matches(QUALIFIED_CLASS_PATTERN)
