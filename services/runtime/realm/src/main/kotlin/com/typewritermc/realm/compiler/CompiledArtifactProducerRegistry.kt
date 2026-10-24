package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationResult
import com.typewritermc.realm.authoring.AuthoringView
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.diagnostic.DiagnosticSeverity

/** Preserves every root result and validates output ownership before storage. */
internal class CompiledArtifactProducerRegistry(
    producers: Collection<CompiledArtifactProducer>,
) {
    private val ordered =
        producers.sortedWith(compareBy({ it.projection.value }, { it.mediaType })).also { values ->
            require(values.map { it.projection to it.mediaType }.distinct().size == values.size) {
                "Compiled artifact producers must have unique projection and media type identities."
            }
        }

    fun roots(view: AuthoringView): Set<CompilationRoot> =
        ordered.flatMapTo(linkedSetOf()) { producer ->
            producer.roots(view).also { roots ->
                require(roots.all { root -> root.projection == producer.projection }) {
                    "Compilation roots must match their producer projection."
                }
            }
        }

    context(inputs: CompilationInputs)
    fun compile(): List<CompilationResult> {
        val results =
            ordered.flatMap { producer ->
                val roots = producer.roots(inputs.view)
                require(roots.all { root -> root.projection == producer.projection }) {
                    "Compilation roots must match their producer projection."
                }
                producer.compile(roots).also { results ->
                    require(results.map { it.root }.toSet() == roots && results.size == roots.size) {
                        "Compilation must report every supplied root exactly once."
                    }
                    require(results.none { it is CompilationResult.Removed }) {
                        "A supplied root cannot be reported as removed."
                    }
                    results.filterIsInstance<CompilationResult.Success>().forEach { result ->
                        require(result.artifact.mediaType == producer.mediaType) {
                            "Compiled output must match its producer media type."
                        }
                    }
                    results.filterIsInstance<CompilationResult.Blocked>().forEach { result ->
                        require(result.diagnostics.any { it.severity == DiagnosticSeverity.ERROR }) {
                            "A blocked root must contain a blocking diagnostic."
                        }
                    }
                }
            }
        require(results.map { it.root }.distinct().size == results.size) {
            "Compiled roots must be unique within one publication."
        }
        return results
    }
}
