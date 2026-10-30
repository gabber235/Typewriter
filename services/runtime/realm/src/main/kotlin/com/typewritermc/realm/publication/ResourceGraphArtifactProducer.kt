package com.typewritermc.realm.publication

import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.RESOURCE_GRAPH_MEDIA_TYPE
import com.typewritermc.engine.RESOURCE_GRAPH_PROJECTION
import com.typewritermc.engine.ResourceGraphCompileResult
import com.typewritermc.engine.decodeResourceGraphShard
import com.typewritermc.engine.encodeShard
import com.typewritermc.engine.semanticDigest
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.catalog.ownershipRelationIds
import com.typewritermc.types.toSkir
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeSelection

/** Compiles every complete compilation unit with its ownership closure into the resource graph format. */
internal object ResourceGraphArtifactProducer : CompiledArtifactProducer {
    override val projection = RESOURCE_GRAPH_PROJECTION
    override val mediaType = RESOURCE_GRAPH_MEDIA_TYPE

    override fun roots(view: AuthoringView): Set<CompilationRoot> =
        view.resources.entries
            .asSequence()
            .filter { (_, record) -> record.isCompilationUnit(view.catalog.checked) }
            .map { (resource, _) -> CompilationRoot(projection = projection, resource = resource) }
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
                            semanticDigest = result.shard.semanticDigest,
                            payload = result.shard.facts.encodeShard(),
                        ),
                    )
                }
            }
        }
    }

    override fun publishedRecord(payload: ByteArray): AuthoringRecord? {
        val facts = payload.decodeResourceGraphShard().facts
        val root = facts.resources.firstOrNull { it.key == facts.root } ?: return null
        val fields = (root.value.payload as? DataValue.RecordWrapper)?.value?.fields ?: return null
        return AuthoringRecord(configuration = TypeSelection.CompleteWrapper(root.actualType), fields = fields)
    }
}
