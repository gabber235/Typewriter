package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationResult
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.types.ResourceId
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot

/** Pins every producer to one retained publication view and the native requirements accepted for that view. */
internal data class CompilationInputs(
    val view: AuthoringView,
    val resources: Map<ResourceId, ResourceReadiness>,
)

internal interface CompiledArtifactProducer {
    val projection: CompilationProjectionId
    val mediaType: String

    fun roots(view: AuthoringView): Set<CompilationRoot>

    context(inputs: CompilationInputs)
    fun compile(roots: Set<CompilationRoot>): List<CompilationResult>
}
