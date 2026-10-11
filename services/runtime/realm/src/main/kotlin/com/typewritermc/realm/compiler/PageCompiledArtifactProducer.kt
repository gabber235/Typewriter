package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
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
    override fun compile(roots: Set<CompilationRoot>): CompilationOutcome {
        require(roots.all { root -> root.projection == projection })
        val ownership =
            inputs.view.catalog.relations
                .filter { relation ->
                    RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in relation.families
                }.mapTo(linkedSetOf(), RelationContract::id)
        val compiler = PageCompiler(ownership, inputs.bindingRequirements.associateBy(NativeBindingRequirement::actual))
        val results =
            roots.sortedBy { root -> root.resource.value }.map { root ->
                root to with(inputs.view) { compiler.compile(root.resource) }
            }
        val blocked = results.mapNotNull { (_, result) -> (result as? PageCompileResult.Blocked)?.diagnostics }.flatten()
        if (blocked.isNotEmpty()) return CompilationOutcome.Blocked(blocked.map { publicationDiagnostic(it.code, it.message) })
        val compiled =
            results.map { (root, result) ->
                result as PageCompileResult.Success
                val shard = result.shard
                CompiledArtifact(
                    root = root,
                    formatRevision = shard.facts.formatRevision,
                    mediaType = mediaType,
                    inputFingerprint = result.inputFingerprint,
                    semanticDigest = shard.digest,
                    payload = shard.facts.encodeShard(),
                )
            }
        return CompilationOutcome.Ready(compiled)
    }
}
