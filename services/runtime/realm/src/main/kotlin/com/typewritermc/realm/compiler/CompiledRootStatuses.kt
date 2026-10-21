package com.typewritermc.realm.compiler

import com.typewritermc.realm.authoring.AuthoringView
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledResourceState
import skirout.editor.v1.type_catalog.PublicationId

internal sealed interface CompilationStatusSelection {
    data object All : CompilationStatusSelection

    data class Supplied(
        val roots: Set<CompilationRoot>,
    ) : CompilationStatusSelection
}

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
                CompilationStatusSelection.All -> compilation.roots(view) + available
                is CompilationStatusSelection.Supplied -> selection.roots
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
