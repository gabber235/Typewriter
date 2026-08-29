package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
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

@JvmInline
@Serializable
value class ProducerId(
    val value: String,
) {
    init {
        require(value.matches(SEGMENT_PATTERN)) { "Producer ids must be safe path segments." }
    }
}

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

@Serializable
data class ContributionKey(
    val origin: ArtifactId,
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
        require(moduleProviderClass.isQualifiedClassName()) { "Module provider classes must use qualified JVM names." }
    }
}

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
