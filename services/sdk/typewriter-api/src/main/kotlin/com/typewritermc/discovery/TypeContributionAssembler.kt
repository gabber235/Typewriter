package com.typewritermc.discovery

import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition

/**
 * Retains a decoded type contribution together with its origin for deterministic assembly and conflict reporting.
 */
data class KeyedTypeContribution(
    val key: ContributionKey,
    val contribution: TypeDiscoveryContribution,
)

/**
 * Retains the originating contribution alongside a runtime module binding so module providers receive provenance.
 */
data class KeyedExecutableBinding(
    val key: ContributionKey,
    val binding: ExecutableBinding,
)

/**
 * Separates the structural catalog from the prototypes and modules that may execute.
 *
 * Definitions can remain visible even when their source part is ineligible. Runtime loaders further filter
 * executable bindings by discovery domain.
 */
data class AssembledTypeDiscovery(
    val catalog: TypeCatalog,
    val relations: List<RelationDefinition>,
    val prototypeBindings: List<PrototypeBinding>,
    val executableBindings: List<KeyedExecutableBinding>,
)

/**
 * Merges generated type contributions in stable origin order.
 *
 * Identical definitions and bindings may be shared; conflicting identities and duplicate contribution keys are
 * rejected. Ineligible source parts still contribute structural definitions but not executable or prototype
 * bindings. A missing eligibility entry does not exclude a binding.
 */
object TypeContributionAssembler {
    /**
     * Merges contributions into the structural catalog and domain specific executable bindings.
     *
     * Contributions are sorted by provenance before conflicts are checked. A source part marked ineligible loses
     * executable and prototype bindings, but its definitions remain available for diagnostics and catalog display.
     */
    fun assemble(
        contributions: Collection<KeyedTypeContribution>,
        sourceParts: Collection<SourcePartCatalogEntry> = emptyList(),
    ): AssembledTypeDiscovery {
        val ordered = contributions.sortedBy { it.key.sortKey() }
        require(ordered.map(KeyedTypeContribution::key).distinct().size == ordered.size) {
            "Discovery contribution keys must be unique."
        }

        val definitions = linkedMapOf<Any, TypeDefinition>()
        StandardTypes.definitions.forEach { definition -> definitions[definition.id] = definition }
        val prototypeBindings = linkedMapOf<Any, PrototypeBinding>()
        val relations = linkedMapOf<RelationId, RelationDefinition>()
        val executableBindings = linkedMapOf<Pair<DiscoveryDomainId, String>, KeyedExecutableBinding>()
        val extensionEligibility = sourceParts.associateBy { it.artifact to it.sourcePart }
        ordered.forEach { keyed ->
            keyed.contribution.definitions.forEach { definition ->
                val previous = definitions[definition.id]
                require(previous == null || previous.copy(displayName = definition.displayName) == definition) {
                    "Conflicting type definition ${definition.id} from ${keyed.key}."
                }
                val defaultName = TypeDefinition(id = definition.id, kind = definition.kind).displayName
                require(previous == null || previous.displayName == definition.displayName ||
                    previous.displayName == defaultName || definition.displayName == defaultName) {
                    "Conflicting type display name ${definition.id} from ${keyed.key}."
                }
                definitions[definition.id] = when {
                    previous == null -> definition
                    previous.displayName == defaultName -> previous.copy(displayName = definition.displayName)
                    else -> previous
                }
            }
            keyed.contribution.relations.forEach { definition ->
                val previous = relations[definition.id]
                relations[definition.id] = previous?.merge(definition) ?: definition
            }
            val eligibility = extensionEligibility[keyed.key.origin to keyed.key.sourcePart]?.eligibility
            if (eligibility is Eligibility.Ineligible) return@forEach
            keyed.contribution.prototypeBindings.forEach { binding ->
                val previous = prototypeBindings.putIfAbsent(binding.type, binding)
                require(previous == null || previous == binding) {
                    "Conflicting prototype binding ${binding.type} from ${keyed.key}."
                }
            }
            keyed.contribution.executableBindings.forEach { binding ->
                val identity = binding.domain to binding.localName
                val candidate = KeyedExecutableBinding(keyed.key, binding)
                val previous = executableBindings.putIfAbsent(identity, candidate)
                require(previous == null || previous.binding == binding) {
                    "Conflicting executable binding $identity from ${previous?.key} and ${keyed.key}."
                }
            }
        }

        return AssembledTypeDiscovery(
            catalog = TypeCatalog(definitions.values.sortedBy { it.id.toString() }),
            relations = relations.values.sortedBy { it.id.value },
            prototypeBindings = prototypeBindings.values.sortedBy { it.type.toString() },
            executableBindings =
                executableBindings.values.sortedWith(
                    compareBy({ it.binding.domain.value }, { it.binding.localName }, { it.key.sortKey() }),
                ),
        )
    }
}

private fun RelationDefinition.merge(other: RelationDefinition): RelationDefinition {
    require(source == other.source && target == other.target) { "Conflicting relation endpoints for $id." }
    require(families == other.families) { "Conflicting relation families for $id." }
    require(onSourceDelete == other.onSourceDelete && onTargetDelete == other.onTargetDelete) {
        "Conflicting relation deletion policy for $id."
    }
    require(sourceEndpoint == null || other.sourceEndpoint == null || sourceEndpoint == other.sourceEndpoint) {
        "Conflicting source endpoint for $id."
    }
    require(targetEndpoint == null || other.targetEndpoint == null || targetEndpoint == other.targetEndpoint) {
        "Conflicting target endpoint for $id."
    }
    return copy(
        sourceEndpoint = sourceEndpoint ?: other.sourceEndpoint,
        targetEndpoint = targetEndpoint ?: other.targetEndpoint,
    )
}

private fun ContributionKey.sortKey(): String = "${origin.value}/$sourcePart/${producer.value}/${name.value}"
