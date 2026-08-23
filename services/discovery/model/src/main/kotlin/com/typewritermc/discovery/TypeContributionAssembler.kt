package com.typewritermc.discovery

import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition

data class KeyedTypeContribution(
    val key: ContributionKey,
    val contribution: TypeDiscoveryContribution,
)

data class AssembledTypeDiscovery(
    val catalog: TypeCatalog,
    val prototypeBindings: List<PrototypeBinding>,
    val executableBindings: List<ExecutableBinding>,
)

object TypeContributionAssembler {
    fun assemble(
        contributions: Collection<KeyedTypeContribution>,
        sourceParts: Collection<SourcePartCatalogEntry> = emptyList(),
    ): AssembledTypeDiscovery {
        val ordered = contributions.sortedBy { it.key.sortKey() }
        require(ordered.map(KeyedTypeContribution::key).distinct().size == ordered.size) {
            "Discovery contribution keys must be unique."
        }

        val definitions = linkedMapOf<Any, TypeDefinition>()
        val prototypeBindings = linkedMapOf<Any, PrototypeBinding>()
        val executableBindings = linkedMapOf<Pair<DiscoveryDomainId, String>, ExecutableBinding>()
        val extensionEligibility = sourceParts.associateBy { it.artifact to it.sourcePart }
        ordered.forEach { keyed ->
            keyed.contribution.definitions.forEach { definition ->
                val previous = definitions.putIfAbsent(definition.id, definition)
                require(previous == null || previous == definition) {
                    "Conflicting type definition ${definition.id} from ${keyed.key}."
                }
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
                val previous = executableBindings.putIfAbsent(identity, binding)
                require(previous == null || previous == binding) {
                    "Conflicting executable binding $identity from ${keyed.key}."
                }
            }
        }

        return AssembledTypeDiscovery(
            catalog = TypeCatalog(definitions.values.sortedBy { it.id.toString() }),
            prototypeBindings = prototypeBindings.values.sortedBy { it.type.toString() },
            executableBindings = executableBindings.values.sortedWith(compareBy({ it.domain.value }, { it.localName })),
        )
    }
}

private fun ContributionKey.sortKey(): String = "${origin.value}/$sourcePart/${producer.value}/${name.value}"
