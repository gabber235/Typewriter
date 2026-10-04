package com.typewritermc.engine.runtime

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.elements.Cue
import com.typewritermc.elements.Element
import com.typewritermc.engine.CompiledEdge
import com.typewritermc.engine.CompiledEdgeOrigin
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledResource
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.library.Page
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution

/** Hydrated resource roles and the compiled links between them. */
class CompiledResourceGraph private constructor(
    val resources: Map<CompiledResourceKey, Any>,
    val edges: List<CompiledEdge>,
    private val ownershipRelations: Set<RelationId>,
) {
    val elements: Map<CompiledResourceKey, Element> =
        resources
            .mapNotNull { (key, value) ->
                (value as? Element)?.let { key to it }
            }.toMap()

    val cues: Map<CompiledResourceKey, Cue> =
        resources
            .mapNotNull { (key, value) ->
                (value as? Cue)?.let { key to it }
            }.toMap()

    fun immediateOwner(key: CompiledResourceKey): CompiledResourceKey? =
        edges
            .singleOrNull { edge ->
                edge.target == key &&
                    (edge.origin as? CompiledEdgeOrigin.Relation)?.relation in ownershipRelations
            }?.source

    fun pageOf(key: CompiledResourceKey): CompiledResourceKey? {
        val visited = hashSetOf<CompiledResourceKey>()
        var current: CompiledResourceKey? = key
        while (current != null && visited.add(current)) {
            if (resources[current] is Page) return current
            current = immediateOwner(current)
        }
        return null
    }

    companion object {
        fun assemble(
            shards: List<CompiledPageShard>,
            relations: Collection<RelationContract>,
            catalog: CheckedCatalog,
            bindings: NativeBindingRegistry,
        ): CompiledResourceGraph {
            val records = linkedMapOf<CompiledResourceKey, CompiledResource>()
            val edges = linkedSetOf<CompiledEdge>()
            shards.forEach { shard ->
                require(shard.resources.any { it.key == shard.root }) {
                    "Compiled Page root is absent from its shard."
                }
                shard.resources.forEach { record ->
                    require(records.putIfAbsent(record.key, record) == null) {
                        "Compiled resource ${record.key} appears in more than one shard."
                    }
                }
                edges.addAll(shard.edges)
            }
            val knownRelations = relations.associateBy(RelationContract::id)
            edges.forEach { edge ->
                val relation = edge.origin as CompiledEdgeOrigin.Relation
                require(relation.relation in knownRelations) {
                    "Compiled edge uses unknown relation ${relation.relation.value}."
                }
            }
            val decoded =
                records.mapValues { (key, record) ->
                    require(record.value.actualType == record.actualType) {
                        "Compiled resource $key has inconsistent actual type evidence."
                    }
                    val checked =
                        when (val resolution = catalog.resolve(record.actualType)) {
                            is Resolution.Ready -> {
                                resolution.value
                            }

                            is Resolution.Invalid -> {
                                error(
                                    "Compiled resource $key has an unresolved actual type: ${resolution.diagnostics}.",
                                )
                            }
                        }
                    val complete =
                        when (val result = checked.complete(record.value)) {
                            is CompletenessResult.Complete -> result.value
                            is CompletenessResult.Unfinished -> error("Compiled resource $key is unfinished at ${result.locations}.")
                            is CompletenessResult.Invalid -> error("Compiled resource $key is invalid: ${result.problems}.")
                        }
                    val binding = bindings.bind(checked)
                    require(binding.provider == record.bindingProvider && binding.signature == record.bindingSignature) {
                        "Compiled resource $key uses a different native binding implementation."
                    }
                    requireNotNull(binding.decode(complete)) {
                        "Compiled resource $key decoded to null."
                    }
                }
            val ownership =
                knownRelations.values
                    .filter { RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in it.families }
                    .mapTo(linkedSetOf(), RelationContract::id)
            return CompiledResourceGraph(decoded, edges.toList(), ownership)
        }
    }
}
