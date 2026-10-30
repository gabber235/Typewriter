package com.typewritermc.realm.publication

import com.typewritermc.engine.CompilationResult
import com.typewritermc.realm.authoring.AuthoringView
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.kernel.v1.resource_id.ResourceId

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

    /** The record a root was compiled from, read back from one of this producer's payloads; null when it carries none. */
    fun publishedRecord(payload: ByteArray): AuthoringRecord?
}
