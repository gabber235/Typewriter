package com.typewritermc.realm.compiler

import com.typewritermc.checking.Diagnostic
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.realm.authoring.AuthoringView

/** Pins every producer to one retained publication view and the native requirements accepted for that view. */
internal data class CompilationInputs(
    val view: AuthoringView,
    val bindingRequirements: List<NativeBindingRequirement>,
)

internal interface CompiledArtifactProducer {
    val projection: CompilationProjectionId
    val mediaType: String

    fun roots(view: AuthoringView): Set<com.typewritermc.engine.CompilationRoot>

    context(inputs: CompilationInputs)
    fun compile(roots: Set<com.typewritermc.engine.CompilationRoot>): CompilationOutcome
}

internal sealed interface CompilationOutcome {
    data class Ready(
        val artifacts: List<CompiledArtifact>,
    ) : CompilationOutcome

    data class Blocked(
        val findings: List<Diagnostic>,
    ) : CompilationOutcome
}
