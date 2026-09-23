package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.realm.CoreResourceDefinitionIds
import com.typewritermc.realm.repository.AuthoringGraphDelta
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/** Projects one Page and its owned resource closure from the authoring graph. */
internal class PageCompilationProjection(
    private val ownershipRelations: Set<RelationId>,
    private val compiler: PageCompiler = PageCompiler(ownershipRelations),
    private val catalogRevision: () -> String,
) : AuthoringCompilationProjection {
    override val id: CompilationProjectionId = CompilationProjectionId("typewriter.page")
    override val root: TypeExpression = TypeExpression.Named(PAGE_CONTRACT_TYPE)
    override val graphRequirement = GraphReadRequirement(
        definitions = setOf(
            CoreResourceDefinitionIds.PAGE,
            CoreResourceDefinitionIds.ELEMENT,
            CoreResourceDefinitionIds.CUE,
        ),
        relations = ownershipRelations,
        includeIncidentEdges = true,
        direction = GraphReadRequirement.Direction.OUTGOING,
        maximumDepth = 256,
    )

    override fun roots(graph: AuthoringWorkingGraph): Set<ResourceId> =
        graph.resources.values.filter { it.definition == CoreResourceDefinitionIds.PAGE }
            .mapTo(linkedSetOf(), StoredTypedResource::id)

    override fun affectedRoots(
        change: AuthoringGraphDelta,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> {
        val changed = buildSet {
            addAll(change.resourceUpserts.keys)
            addAll(change.resourceRemovals)
            change.relationUpserts.values.forEach { add(it.source); add(it.target) }
            change.relationUpdates.forEach { id ->
                listOfNotNull(before.relations[id], proposed.relations[id]).forEach {
                    add(it.source)
                    add(it.target)
                }
            }
            change.relationRemovals.forEach { id ->
                before.relations[id]?.let { add(it.source); add(it.target) }
            }
        }
        return before.pageRoots(changed) + proposed.pageRoots(changed)
    }

    override suspend fun compile(root: ResourceId, graph: AuthoringWorkingGraph): CompilationResult {
        if (graph.resources[root]?.definition != CoreResourceDefinitionIds.PAGE) {
            return CompilationResult.Removed(com.typewritermc.engine.CompilationRoot(id, root))
        }
        val input = graph.ownedPageSlice(root)
        return when (val result = compiler.compile(root, input, catalogRevision())) {
            is PageCompileResult.Blocked -> CompilationResult.Blocked(
                root = com.typewritermc.engine.CompilationRoot(id, root),
                inputFingerprint = result.inputFingerprint,
                diagnostics = result.diagnostics,
            )
            is PageCompileResult.Success -> {
                val payload = json.encodeToString(result.shard).encodeToByteArray()
                CompilationResult.Success(
                    com.typewritermc.engine.CompiledArtifact(
                        root = com.typewritermc.engine.CompilationRoot(id, root),
                        formatRevision = result.shard.formatRevision,
                        mediaType = MEDIA_TYPE,
                        inputFingerprint = result.shard.inputFingerprint,
                        semanticDigest = result.shard.digest,
                        payload = payload,
                    ),
                )
            }
        }
    }

    private fun AuthoringWorkingGraph.ownedPageSlice(root: ResourceId): AuthoringWorkingGraph {
        val owned = linkedSetOf(root)
        val frontier = ArrayDeque<ResourceId>()
        frontier.add(root)
        while (frontier.isNotEmpty()) {
            val parent = frontier.removeFirst()
            relations.values.forEach { edge ->
                if (edge.source != parent || !edge.isOwnership()) return@forEach
                if (edge.target in resources && owned.add(edge.target)) frontier.add(edge.target)
            }
        }
        return AuthoringWorkingGraph(
            resources = resources.filterKeys(owned::contains),
            relations = relations.filterValues { it.source in owned || it.target in owned },
        )
    }

    private fun AuthoringWorkingGraph.pageRoots(changed: Collection<ResourceId>): Set<ResourceId> = buildSet {
        val visited = hashSetOf<ResourceId>()
        val frontier = ArrayDeque(changed)
        while (frontier.isNotEmpty()) {
            val current = frontier.removeFirst()
            if (!visited.add(current)) continue
            if (resources[current]?.definition == CoreResourceDefinitionIds.PAGE) add(current)
            relations.values.forEach { edge ->
                if (edge.target == current && edge.isOwnership()) frontier.add(edge.source)
            }
        }
    }

    private fun StoredResourceRelation.isOwnership(): Boolean =
        (origin as? ResourceRelationOrigin.Declared)?.relationId in ownershipRelations

    private companion object {
        const val MEDIA_TYPE = "application/vnd.typewriter.page+json"
        val json = Json { encodeDefaults = true }
    }
}
