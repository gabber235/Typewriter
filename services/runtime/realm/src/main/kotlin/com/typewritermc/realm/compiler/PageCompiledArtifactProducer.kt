package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationFamilyId
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/** Owns nominal Page root selection, ownership traversal, and the serialized Page shard format. */
internal class PageCompiledArtifactProducer : CompiledArtifactProducer {
    override val projection = CompilationProjectionId("typewriter.page")
    override val mediaType = "application/vnd.typewriter.page+json"

    override fun compile(inputs: CompilationInputs): CompilationOutcome {
        val root = inputs.view
        val bindingRequirements = inputs.bindingRequirements
        val ownership =
            root.catalog.relations
                .filter { relation ->
                    RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in relation.families
                }.mapTo(linkedSetOf(), RelationContract::id)
        val compiler = PageCompiler(ownership, bindingRequirements.associateBy(NativeBindingRequirement::actual))
        val pageRoots =
            root.resources
                .filterValues { record ->
                    val selection = record.configuration as? com.typewritermc.authoring.TypeSelection.Complete
                    selection != null && root.catalog.checked.isNominalSubtype(selection.use.definition, PAGE_CONTRACT_TYPE)
                }.keys
                .sortedBy { it.value }
        val results = pageRoots.map { page -> page to compiler.compile(page, root) }
        val blocked = results.mapNotNull { (_, result) -> (result as? PageCompileResult.Blocked)?.diagnostics }.flatten()
        if (blocked.isNotEmpty()) return CompilationOutcome.Blocked(blocked.map { publicationDiagnostic(it.code, it.message) })
        val compiled =
            results.map { (page, result) ->
                val shard = (result as PageCompileResult.Success).shard
                CompiledArtifact(
                    root = CompilationRoot(projection, page),
                    formatRevision = shard.formatRevision,
                    mediaType = mediaType,
                    inputFingerprint = shard.inputFingerprint,
                    semanticDigest = shard.digest,
                    payload = pagePublicationJson.encodeToString(shard).encodeToByteArray(),
                )
            }
        return CompilationOutcome.Ready(compiled)
    }
}

private val pagePublicationJson = Json { encodeDefaults = true }
