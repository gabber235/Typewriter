package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import com.typewritermc.engine.PublishedContent

/** Semantic release contents independent of storage pointers or publication IDs. */
data class PublicationRuntimeContent(
    val formatRevision: Int,
    val roots: Map<CompilationRoot, CompiledArtifactReference>,
    val implementationToken: String,
    val signatures: Set<com.typewritermc.scripting.RuntimeMemberSignature>,
) {
    companion object {
        fun selected(content: PublishedContent) =
            PublicationRuntimeContent(
                content.formatRevision,
                content.outputs.associate { it.reference.root to it.reference },
                content.implementationToken,
                content.runtimeSignatures,
            )

        fun prepared(
            artifacts: List<CompiledArtifact>,
            engine: EngineImplementationInputs,
        ) = PublicationRuntimeContent(
            PUBLISHED_CONTENT_FORMAT_REVISION,
            artifacts.associate { it.root to CompiledArtifactReference(it.root, it.formatRevision, it.mediaType, it.semanticDigest) },
            engine.token.value,
            engine.signatures,
        )
    }
}

sealed interface PublicationChange {
    data class RootAdded(
        val root: CompilationRoot,
    ) : PublicationChange

    data class RootUpdated(
        val root: CompilationRoot,
    ) : PublicationChange

    data class RootRemoved(
        val root: CompilationRoot,
    ) : PublicationChange

    data object RequirementsChanged : PublicationChange
}

/** A release requires at least one change in what the runtime receives. */
@ConsistentCopyVisibility
data class PublicationDelta internal constructor(
    val first: PublicationChange,
    val additional: List<PublicationChange> = emptyList(),
) {
    val allChanges: List<PublicationChange> get() = listOf(first) + additional

    init {
        require(allChanges.distinct().size == allChanges.size)
    }
}

sealed interface PublicationComparison {
    data object Unchanged : PublicationComparison

    data class Changed(
        val delta: PublicationDelta,
    ) : PublicationComparison

    companion object {
        fun between(
            selected: PublishedContent?,
            artifacts: List<CompiledArtifact>,
            engine: EngineImplementationInputs,
        ): PublicationComparison {
            val changes = confirmedChanges(selected, artifacts, artifacts.mapTo(linkedSetOf()) { it.root }, engine)
            return if (changes.isEmpty()) Unchanged else Changed(PublicationDelta(changes.first(), changes.drop(1)))
        }

        /** Failed roots remain pending. Successful roots and definite removals can still be compared. */
        fun confirmedChanges(
            selected: PublishedContent?,
            artifacts: List<CompiledArtifact>,
            candidateRoots: Set<CompilationRoot>,
            engine: EngineImplementationInputs,
        ): List<PublicationChange> {
            require(artifacts.map { it.root }.distinct().size == artifacts.size) { "Candidate roots must be unique." }
            require(artifacts.all { it.root in candidateRoots }) { "Successful output must belong to the candidate." }
            return confirmedChanges(selected?.let(PublicationRuntimeContent::selected), artifacts, candidateRoots, engine)
        }

        fun confirmedChanges(
            selected: PublicationRuntimeContent?,
            artifacts: List<CompiledArtifact>,
            candidateRoots: Set<CompilationRoot>,
            engine: EngineImplementationInputs,
        ): List<PublicationChange> {
            require(artifacts.map { it.root }.distinct().size == artifacts.size)
            require(artifacts.all { it.root in candidateRoots })
            val old = selected?.roots.orEmpty()
            val next =
                artifacts.associate { artifact ->
                    artifact.root to
                        CompiledArtifactReference(
                            artifact.root,
                            artifact.formatRevision,
                            artifact.mediaType,
                            artifact.semanticDigest,
                        )
                }
            val ordering = compareBy<CompilationRoot>({ it.projection.value }, { it.resource.value })
            return buildList {
                (old.keys + candidateRoots).sortedWith(ordering).forEach { root ->
                    when {
                        root !in candidateRoots -> add(PublicationChange.RootRemoved(root))
                        root !in next -> Unit
                        root !in old -> add(PublicationChange.RootAdded(root))
                        old[root] != next[root] -> add(PublicationChange.RootUpdated(root))
                    }
                }
                if (selected != null &&
                    (
                        selected.formatRevision != PUBLISHED_CONTENT_FORMAT_REVISION ||
                            selected.implementationToken != engine.token.value || selected.signatures != engine.signatures
                    )
                ) {
                    add(PublicationChange.RequirementsChanged)
                }
            }
        }
    }
}
