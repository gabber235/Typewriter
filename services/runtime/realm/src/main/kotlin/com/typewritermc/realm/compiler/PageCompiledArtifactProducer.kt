package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.engine.encodeShard
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationFamilyId

/** Owns nominal Page root selection, ownership traversal, and the serialized Page shard format. */
internal class PageCompiledArtifactProducer : CompiledArtifactProducer {
    override val projection = CompilationProjectionId("typewriter.page")
    override val mediaType = "application/vnd.typewriter.page+json"

    override fun roots(view: AuthoringView): Set<CompilationRoot> =
        view.resources.entries
            .asSequence()
            .filter { (_, record) ->
                val selection = record.configuration as? com.typewritermc.authoring.TypeSelection.Complete
                selection != null && view.catalog.checked.isNominalSubtype(selection.use.definition, PAGE_CONTRACT_TYPE)
            }.map { (resource, _) -> CompilationRoot(projection, resource) }
            .sortedBy { root -> root.resource.value }
            .toCollection(linkedSetOf())

    context(inputs: CompilationInputs)
    override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> {
        require(roots.all { root -> root.projection == projection })
        val ownership =
            inputs.view.catalog.relations
                .filter { relation ->
                    RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in relation.families
                }.mapTo(linkedSetOf(), RelationContract::id)
        val compiler = PageCompiler(ownership, inputs.resources)
        return roots.sortedBy { root -> root.resource.value }.map { root ->
            when (val result = with(inputs.view) { compiler.compile(root.resource) }) {
                is PageCompileResult.Blocked -> {
                    CompilationResult.Blocked(root, result.inputFingerprint, result.diagnostics)
                }

                is PageCompileResult.Success -> {
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
