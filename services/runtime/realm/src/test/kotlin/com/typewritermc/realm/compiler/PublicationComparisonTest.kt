package com.typewritermc.realm.compiler

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputToken
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.PublishedOutput
import com.typewritermc.engine.toSkir
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.publication.PublicationChange

val PublicationComparisonTest by testSuite {
    test("publication identity catalog provenance input fingerprints and blob pointers are not runtime changes") {
        val artifact = comparisonArtifact()
        val selected = comparisonSelected(artifact)
        val candidate = artifact.copy(inputFingerprint = ContentDigest("c".repeat(64)))
        PublicationComparison.between(
            selected.copy(publication = PublicationId("other"), catalog = CatalogGeneration("other")),
            listOf(candidate),
            testEngineInputs(),
        ) shouldBe
            PublicationComparison.Unchanged
    }
    test("format media and semantic digest changes each update the root") {
        val original = comparisonArtifact()
        val selected = comparisonSelected(original)
        listOf(
            original.copy(formatRevision = 3),
            original.copy(mediaType = "application/other"),
            original.copy(semanticDigest = ContentDigest("b".repeat(64))),
        ).forEach { artifact ->
            PublicationComparison
                .between(
                    selected,
                    listOf(artifact),
                    testEngineInputs(),
                ).shouldBeInstanceOf<PublicationComparison.Changed>()
                .delta.allChanges shouldBe
                listOf(PublicationChange.RootUpdatedWrapper(original.root.toSkir()))
        }
    }
    test("token changes are meaningful even with no roots") {
        val selected = comparisonSelected(comparisonArtifact()).copy(outputs = emptyList())
        PublicationComparison
            .between(
                selected,
                emptyList(),
                EngineImplementationInputs(InputToken("new")),
            ).shouldBeInstanceOf<PublicationComparison.Changed>()
            .delta.allChanges shouldBe
            listOf(PublicationChange.REQUIREMENTS_CHANGED)
        PublicationComparison.between(null, emptyList(), testEngineInputs()) shouldBe PublicationComparison.Unchanged
    }
    test("old envelope format requires explicit publication even without changed output") {
        val artifact = comparisonArtifact()
        for (outputs in listOf(comparisonSelected(artifact), comparisonSelected(artifact).copy(outputs = emptyList()))) {
            val candidate = if (outputs.outputs.isEmpty()) emptyList() else listOf(artifact)
            PublicationComparison
                .between(
                    outputs.copy(formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION + 1),
                    candidate,
                    testEngineInputs(),
                ).shouldBeInstanceOf<PublicationComparison.Changed>()
                .delta.allChanges shouldBe
                listOf(PublicationChange.REQUIREMENTS_CHANGED)
            PublicationComparison.between(outputs, candidate, testEngineInputs()) shouldBe PublicationComparison.Unchanged
        }
    }
    test("failed roots remain pending while definite removals and successful additions are comparable") {
        val old = comparisonArtifact()
        val fresh = comparisonArtifact("new")
        val pending = comparisonArtifact("pending").root
        PublicationComparison.confirmedChanges(
            comparisonSelected(old),
            listOf(fresh),
            setOf(fresh.root, pending),
            testEngineInputs(),
        ) shouldBe
            listOf(PublicationChange.RootAddedWrapper(fresh.root.toSkir()), PublicationChange.RootRemovedWrapper(old.root.toSkir()))
    }
    test("a release delta is nonempty and lists each change once") {
        shouldThrow<IllegalArgumentException> { publicationDelta(emptyList()) }
        shouldThrow<IllegalArgumentException> {
            publicationDelta(listOf(PublicationChange.REQUIREMENTS_CHANGED, PublicationChange.REQUIREMENTS_CHANGED))
        }
        val root = comparisonArtifact().root.toSkir()
        publicationDelta(listOf(PublicationChange.RootAddedWrapper(root), PublicationChange.REQUIREMENTS_CHANGED))
            .allChanges shouldBe listOf(PublicationChange.RootAddedWrapper(root), PublicationChange.REQUIREMENTS_CHANGED)
    }
}

private fun comparisonArtifact(id: String = "root") =
    CompiledArtifact(
        CompilationRoot(CompilationProjectionId("fixture"), ResourceId(id)),
        2,
        "application/fixture",
        ContentDigest("1".repeat(64)),
        ContentDigest("a".repeat(64)),
        byteArrayOf(1),
    )

private fun comparisonSelected(artifact: CompiledArtifact) =
    PublishedContent(
        PublicationId("selected"),
        com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
        CatalogGeneration("catalog"),
        "implementation",
        listOf(
            PublishedOutput(
                CompiledArtifactReference(artifact.root, artifact.formatRevision, artifact.mediaType, artifact.semanticDigest),
                CompiledBlobPointer(ContentDigest("2".repeat(64)), 1),
            ),
        ),
    )
