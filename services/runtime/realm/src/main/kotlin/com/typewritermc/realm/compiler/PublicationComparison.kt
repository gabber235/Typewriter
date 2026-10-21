package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationChange
import skirout.editor.v1.publication.PublicationDelta

/** Semantic release contents independent of storage pointers or publication IDs. */
data class PublicationRuntimeContent(
    val formatRevision: Int,
    val roots: Map<CompilationRoot, CompiledArtifactReference>,
    val implementationToken: String,
) {
    companion object {
        fun selected(content: PublishedContent) =
            PublicationRuntimeContent(
                content.formatRevision,
                content.outputs.associate { it.reference.root to it.reference },
                content.implementationToken,
            )

        fun prepared(
            artifacts: List<CompiledArtifact>,
            engine: EngineImplementationInputs,
        ) = PublicationRuntimeContent(
            PUBLISHED_CONTENT_FORMAT_REVISION,
            artifacts.associate {
                it.root to
                    CompiledArtifactReference(
                        root = it.root,
                        formatRevision = it.formatRevision,
                        mediaType = it.mediaType,
                        semanticDigest = it.semanticDigest.value,
                    )
            },
            engine.token.value,
        )
    }
}

/** A releasable change set: nonempty with distinct changes, the first one first. */
internal fun publicationDelta(changes: List<PublicationChange>): PublicationDelta {
    require(changes.isNotEmpty()) { "A publication delta needs at least one change." }
    require(changes.distinct().size == changes.size) { "Publication delta changes must be distinct." }
    return PublicationDelta(first = changes.first(), additional = changes.drop(1))
}

val PublicationDelta.allChanges: List<PublicationChange> get() = listOf(first) + additional

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
            return if (changes.isEmpty()) Unchanged else Changed(publicationDelta(changes))
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
                            root = artifact.root,
                            formatRevision = artifact.formatRevision,
                            mediaType = artifact.mediaType,
                            semanticDigest = artifact.semanticDigest.value,
                        )
                }
            val ordering = compareBy<CompilationRoot>({ it.projection.value }, { it.resource.value })
            return buildList {
                (old.keys + candidateRoots).sortedWith(ordering).forEach { root ->
                    when {
                        root !in candidateRoots -> add(PublicationChange.RootRemovedWrapper(root))
                        root !in next -> Unit
                        root !in old -> add(PublicationChange.RootAddedWrapper(root))
                        old[root] != next[root] -> add(PublicationChange.RootUpdatedWrapper(root))
                    }
                }
                if (selected != null &&
                    (
                        selected.formatRevision != PUBLISHED_CONTENT_FORMAT_REVISION ||
                            selected.implementationToken != engine.token.value
                    )
                ) {
                    add(PublicationChange.REQUIREMENTS_CHANGED)
                }
            }
        }
    }
}
