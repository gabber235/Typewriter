@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.expression.ExpressionFactories
import skirout.editor.v1.presentation.PresentationNode
import java.util.IdentityHashMap

/**
 * Resolves provider references by instance identity within one catalog runtime and captures each build independently.
 * References can register several descriptors; the checked template selects the most specific applicable target and
 * rejects ambiguity. Layout state and dependencies belong to a fresh [PresentationBuildState] for each build.
 */
class DefaultPresentationRuntime : PresentationRuntime {
    private val expressions = ExpressionFactories()

    private val presentations = IdentityHashMap<PresentationReference, MutableList<PresentationDescriptor>>()

    override fun register(
        reference: PresentationReference,
        descriptor: PresentationDescriptor,
    ) {
        synchronized(presentations) {
            val registered = presentations[reference].orEmpty()
            val previous = registered.singleOrNull { it.id == descriptor.id }
            require(previous == null || previous == descriptor) {
                "One presentation id cannot describe different providers in one catalog runtime."
            }
            if (previous == null) presentations.getOrPut(reference, ::mutableListOf) += descriptor
        }
    }

    private fun resolve(
        reference: PresentationReference,
        binding: CheckedPresentationTemplate,
    ): com.typewritermc.types.PresentationId? =
        synchronized(presentations) {
            binding.select(presentations[reference].orEmpty())?.id
        }

    override fun build(
        binding: PresentationBuildBinding,
        content: (PresentationBuildScope) -> Unit,
    ): PresentationBuildResult {
        val state = PresentationBuildState(binding, ::resolve, expressions)
        val nodes = mutableListOf<PresentationNode>()
        state.withTarget(nodes) { content(state.scope(target = nodes)) }
        return state.result(state.column(nodes))
    }
}
