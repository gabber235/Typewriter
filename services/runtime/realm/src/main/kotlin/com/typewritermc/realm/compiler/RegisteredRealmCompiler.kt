package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.types.ResourceId
import java.security.MessageDigest

/** Coordinates registered projections without knowing any projection specific payload type. */
internal class RegisteredRealmCompiler(
    private val projections: AuthoringCompilationProjectionRegistry,
    private val content: RegisteredCompiledContentRepository,
    private val artifacts: RegisteredCompiledArtifactStore,
    private val onStatesChanged: suspend (String, Map<CompilationRoot, RegisteredCompiledState>) -> Unit = { _, _ -> },
) {
    suspend fun compile(
        sourceRevision: String,
        catalogRevision: String,
        impact: CompilationImpact,
        graph: suspend (AuthoringCompilationProjection, ResourceId) -> AuthoringWorkingGraph,
    ): RegisteredCompileResult {
        val results =
            buildList {
                projections.projections.forEach { projection ->
                    val roots = impact.rootsFor(projection.id).sortedBy { it.value }
                    if (roots.isEmpty()) return@forEach
                    roots.forEach { root ->
                        add(projection.compile(root, graph(projection, root)))
                    }
                }
            }
        val blocked = results.filterIsInstance<CompilationResult.Blocked>()
        if (blocked.isNotEmpty()) {
            val roots = results.map(CompilationResult::root)
            content.recordBlocked(
                sourceRevision = sourceRevision,
                catalogRevision = catalogRevision,
                roots = roots,
                diagnostics = blocked.flatMap(CompilationResult.Blocked::diagnostics),
            )
            onStatesChanged(sourceRevision, content.states(roots.toSet()))
            return RegisteredCompileResult.Blocked(blocked.flatMap(CompilationResult.Blocked::diagnostics))
        }
        val active = content.activeManifest()
        val replaced = results.mapTo(linkedSetOf(), CompilationResult::root)
        val references =
            active
                ?.artifacts
                .orEmpty()
                .filterNot { it.root in replaced }
                .toMutableList()
        references +=
            results
                .filterIsInstance<CompilationResult.Success>()
                .map { it.artifact.reference() }
        val ordered = references.sortedWith(compareBy({ it.root.projection.value }, { it.root.resource.value }))
        val manifest =
            CompiledArtifactManifest(
                formatRevision = COMPILER_FORMAT,
                digest = manifestDigest(sourceRevision, catalogRevision, ordered),
                sourceRevision = sourceRevision,
                catalogRevision = catalogRevision,
                artifacts = ordered,
            )
        val successful = results.filterIsInstance<CompilationResult.Success>().map(CompilationResult.Success::artifact)
        val activation = artifacts.store(content.nextActivationRevision(), manifest, successful)
        if (!content.publish(manifest, successful, activation)) return RegisteredCompileResult.Stale
        onStatesChanged(sourceRevision, content.states(replaced))
        return RegisteredCompileResult.Activated(manifest, activation)
    }

    private fun CompiledArtifact.reference() =
        CompiledArtifactReference(
            root = root,
            formatRevision = formatRevision,
            mediaType = mediaType,
            semanticDigest = semanticDigest,
        )

    private companion object {
        const val COMPILER_FORMAT = 1

        fun manifestDigest(
            sourceRevision: String,
            catalogRevision: String,
            artifacts: List<CompiledArtifactReference>,
        ): ContentDigest {
            val facts =
                buildString {
                    append("format:").append(COMPILER_FORMAT)
                    append("|source:").append(sourceRevision)
                    append("|catalog:").append(catalogRevision)
                    artifacts.forEach {
                        append("|root:").append(it.root.projection.value).append(':').append(it.root.resource.value)
                        append("|").append(it.mediaType).append(':').append(it.semanticDigest.value)
                    }
                }
            return ContentDigest(
                MessageDigest.getInstance("SHA-256").digest(facts.encodeToByteArray()).joinToString("") {
                    "%02x".format(it.toInt() and 0xff)
                },
            )
        }
    }
}

sealed interface RegisteredCompileResult {
    data object Stale : RegisteredCompileResult

    data class Activated(
        val manifest: CompiledArtifactManifest,
        val activation: CompiledArtifactActivation,
    ) : RegisteredCompileResult

    data class Blocked(
        val diagnostics: List<com.typewritermc.engine.CompileDiagnostic>,
    ) : RegisteredCompileResult
}
