package com.typewritermc.realm.compiler

import com.typewritermc.checking.Diagnostic
import com.typewritermc.engine.CompiledArtifact

/** Compiles one complete batch and rejects ambiguous output ownership before anything is stored. */
internal class CompiledArtifactProducerRegistry(
    producers: Collection<CompiledArtifactProducer>,
) {
    private val ordered =
        producers.sortedWith(compareBy({ it.projection.value }, { it.mediaType })).also { values ->
            require(values.map { it.projection to it.mediaType }.distinct().size == values.size) {
                "Compiled artifact producers must have unique projection and media type identities."
            }
        }

    fun compile(inputs: CompilationInputs): CompilationOutcome {
        val artifacts = mutableListOf<CompiledArtifact>()
        val findings = mutableListOf<Diagnostic>()
        var blocked = false
        ordered.forEach { producer ->
            when (val result = producer.compile(inputs)) {
                is CompilationOutcome.Blocked -> {
                    blocked = true
                    findings += result.findings
                }

                is CompilationOutcome.Ready -> {
                    require(result.artifacts.all { it.root.projection == producer.projection && it.mediaType == producer.mediaType }) {
                        "Compiled output must match its producer projection and media type."
                    }
                    artifacts += result.artifacts
                }
            }
        }
        if (blocked) return CompilationOutcome.Blocked(findings)
        require(artifacts.map { it.root }.distinct().size == artifacts.size) {
            "Compiled output roots must be unique within one publication."
        }
        return CompilationOutcome.Ready(artifacts)
    }
}
