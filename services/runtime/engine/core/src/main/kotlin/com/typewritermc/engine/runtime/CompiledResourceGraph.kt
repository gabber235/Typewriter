package com.typewritermc.engine.runtime

import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.elements.Cue
import com.typewritermc.elements.Element
import com.typewritermc.engine.Root
import com.typewritermc.engine.dataValue
import com.typewritermc.engine.relation
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledEdge
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import kotlin.reflect.KClass

/** Hydrated resource roles and the compiled links between them. */
class CompiledResourceGraph private constructor(
    val resources: Map<CompiledResourceKey, Any>,
    val edges: List<CompiledEdge>,
    /** The Kotlin classes of each resource's type arguments, such as `BlockBreak` for `CancelableEventEntry<BlockBreak>`. */
    val typeArguments: Map<CompiledResourceKey, List<KClass<*>>>,
    /** Each resource as it was stored, with its checked type: what formulas read fields and lower Var types from. */
    val stored: Map<CompiledResourceKey, CompleteValue>,
    /** The resources the publication compiles roots of, one per shard. */
    val roots: Set<ResourceId>,
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

    /** The resource [id] at its root compilation, or null when the publication does not hold it. */
    fun resource(id: ResourceId): Any? = resources[CompiledResourceKey(source = id.toSkir(), context = CompilationContext.Root)]

    companion object {
        fun assemble(
            facts: List<RuntimeCompilationFacts>,
            relations: Collection<RelationContract>,
            catalog: CheckedCatalog,
            bindings: NativeBindingRegistry,
        ): CompiledResourceGraph {
            val records = linkedMapOf<CompiledResourceKey, CompiledResource>()
            val edges = linkedSetOf<CompiledEdge>()
            facts.forEach { compilation ->
                require(compilation.resources.any { it.key == compilation.root }) {
                    "A compiled root is absent from its shard."
                }
                compilation.resources.forEach { record ->
                    require(records.putIfAbsent(record.key, record) == null) {
                        "Compiled resource ${record.key} appears in more than one shard."
                    }
                }
                edges.addAll(compilation.edges)
            }
            val knownRelations = relations.associateBy(RelationContract::id)
            edges.forEach { edge ->
                require(edge.relation in knownRelations) {
                    "Compiled edge uses unknown relation ${edge.relation.value}."
                }
            }
            val stored = linkedMapOf<CompiledResourceKey, CompleteValue>()
            val decoded =
                records.mapValues { (key, record) ->
                    require(record.value.actualType == record.actualType) {
                        "Compiled resource $key has inconsistent actual type evidence."
                    }
                    val checked =
                        when (val resolution = catalog.resolve(record.actualType.use)) {
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
                        when (val result = checked.complete(record.dataValue)) {
                            is CompletenessResult.Complete -> result.value
                            is CompletenessResult.Unfinished -> error("Compiled resource $key is unfinished at ${result.locations}.")
                            is CompletenessResult.Invalid -> error("Compiled resource $key is invalid: ${result.problems}.")
                        }
                    stored[key] = complete
                    val binding = bindings.bind(checked)
                    require(binding.provider == record.bindingProvider && binding.signature == record.bindingSignature) {
                        "Compiled resource $key uses a different native binding implementation."
                    }
                    requireNotNull(binding.decode(complete)) {
                        "Compiled resource $key decoded to null."
                    }
                }
            val typeArguments =
                records.mapValues { (_, record) ->
                    record.actualType.arguments.mapNotNull { argument ->
                        (catalog.resolve(argument) as? Resolution.Ready)?.let { bindings.bind(it.value).nativeClass }
                    }
                }
            val roots = facts.mapTo(linkedSetOf()) { it.root.source.toResourceId() }
            return CompiledResourceGraph(decoded, edges.toList(), typeArguments, stored, roots)
        }
    }
}
