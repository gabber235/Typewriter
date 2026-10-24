package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.authoring.AuthoringView

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
    ): Map<CompilationRoot, RegisteredCompiledState> {
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
                    RegisteredCompiledState.Active(requireNotNull(selected).publication)
                } else {
                    RegisteredCompiledState.NotCompiled
                }
            }
    }
}
