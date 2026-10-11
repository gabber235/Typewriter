package com.typewritermc.presentation

import com.typewritermc.expression.ExpressionFactories
import java.util.IdentityHashMap

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
        state.withTarget(state.nodes) { content(state.scope()) }
        return state.result(state.column(state.nodes))
    }
}
