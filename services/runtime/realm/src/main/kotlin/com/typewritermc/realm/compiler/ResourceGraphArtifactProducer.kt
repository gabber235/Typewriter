package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.RESOURCE_GRAPH_MEDIA_TYPE
import com.typewritermc.engine.RESOURCE_GRAPH_PROJECTION
import com.typewritermc.engine.ResourceGraphCompileResult
import com.typewritermc.engine.encodeShard
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.ownershipRelationIds

/** Compiles every complete compilation unit with its ownership closure into the resource graph format. */
internal object ResourceGraphArtifactProducer : CompiledArtifactProducer {
    override val projection = RESOURCE_GRAPH_PROJECTION
    override val mediaType = RESOURCE_GRAPH_MEDIA_TYPE

    override fun roots(view: AuthoringView): Set<CompilationRoot> =
        view.resources.entries
            .asSequence()
            .filter { (_, record) -> record.isCompilationUnit(view.catalog.checked) }
            .map { (resource, _) -> CompilationRoot(projection, resource) }
            .sortedBy { root -> root.resource.value }
            .toCollection(linkedSetOf())

    context(inputs: CompilationInputs)
    override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> {
        require(roots.all { root -> root.projection == projection })
        val compiler = OwnershipClosureCompiler(inputs.view.catalog.ownershipRelationIds, inputs.resources)
        return roots.sortedBy { root -> root.resource.value }.map { root ->
            when (val result = with(inputs.view) { compiler.compile(root.resource) }) {
                is ResourceGraphCompileResult.Blocked -> {
                    CompilationResult.Blocked(root, result.inputFingerprint, result.diagnostics)
                }

                is ResourceGraphCompileResult.Success -> {
                    CompilationResult.Success(
                        CompiledArtifact(
                            root = root,
                            formatRevision = result.shard.facts.formatRevision,
                            mediaType = mediaType,
                            inputFingerprint = result.inputFingerprint,
                            semanticDigest = result.shard.digest,
                            payload = result.shard.facts.encodeShard(),
                        ),
                    )
                }
            }
        }
    }
}
