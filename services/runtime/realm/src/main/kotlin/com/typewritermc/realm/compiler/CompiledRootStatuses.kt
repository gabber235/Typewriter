package com.typewritermc.realm.compiler

import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompilationStatusSelection
import skirout.editor.v1.compiled_content.CompiledResourceState
import skirout.editor.v1.type_catalog.PublicationId

internal class CompiledRootStatuses(
    private val compilation: CompiledArtifactProducerRegistry,
    private val results: PublicationResults,
) {
    suspend fun query(
        view: AuthoringView,
        selection: CompilationStatusSelection,
    ): Map<CompilationRoot, CompiledResourceState> {
        val selected = results.selected()
        val available = selected?.outputs?.mapTo(linkedSetOf()) { output -> output.reference.root }.orEmpty()
        val roots =
            when (selection) {
                CompilationStatusSelection.ALL_ROOTS -> compilation.roots(view) + available
                is CompilationStatusSelection.SuppliedRootsWrapper -> selection.value
                else -> unknownVariant(selection)
            }
        return roots
            .sortedWith(compareBy({ root -> root.projection.value }, { root -> root.resource.value }))
            .associateWithTo(linkedMapOf()) { root ->
                if (root in available) {
                    CompiledResourceState.ActiveWrapper(PublicationId(value = requireNotNull(selected).publication.value))
                } else {
                    CompiledResourceState.NOT_COMPILED
                }
            }
    }
}
