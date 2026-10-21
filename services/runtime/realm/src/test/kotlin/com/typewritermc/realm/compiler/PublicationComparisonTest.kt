package com.typewritermc.realm.compiler

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.toSkir
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationChange
import skirout.editor.v1.type_catalog.PublicationId

val PublicationComparisonTest by testSuite {
    test("publication identity catalog provenance input fingerprints and blob pointers are not runtime changes") {
        val artifact = comparisonArtifact()
        val selected = comparisonSelected(artifact)
        val candidate = artifact.copy(inputFingerprint = ContentDigest("c".repeat(64)))
        PublicationComparison.between(
            selected.copy(publication = PublicationId(value = "other"), catalog = CatalogGeneration("other").toSkir()),
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
                listOf(PublicationChange.RootUpdatedWrapper(original.root))
        }
    }
    test("token changes are meaningful even with no roots") {
        val selected = comparisonSelected(comparisonArtifact()).copy(outputs = emptyList())
        PublicationComparison
            .between(
                selected,
                emptyList(),
                EngineImplementationInputs(
                    token =
                        skirout.editor.v1.type_catalog
                            .InputToken(value = "new"),
                ),
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
            listOf(PublicationChange.RootAddedWrapper(fresh.root), PublicationChange.RootRemovedWrapper(old.root))
    }
    test("a release delta is nonempty and lists each change once") {
        shouldThrow<IllegalArgumentException> { publicationDelta(emptyList()) }
        shouldThrow<IllegalArgumentException> {
            publicationDelta(listOf(PublicationChange.REQUIREMENTS_CHANGED, PublicationChange.REQUIREMENTS_CHANGED))
        }
        val root = comparisonArtifact().root
        publicationDelta(listOf(PublicationChange.RootAddedWrapper(root), PublicationChange.REQUIREMENTS_CHANGED))
            .allChanges shouldBe listOf(PublicationChange.RootAddedWrapper(root), PublicationChange.REQUIREMENTS_CHANGED)
    }
}

private fun comparisonArtifact(id: String = "root") =
    CompiledArtifact(
        CompilationRoot(projection = CompilationProjectionId(value = "fixture"), resource = ResourceId(id).toSkir()),
        2,
        "application/fixture",
        ContentDigest("1".repeat(64)),
        ContentDigest("a".repeat(64)),
        byteArrayOf(1),
    )

private fun comparisonSelected(artifact: CompiledArtifact) =
    PublishedContent(
        publication = PublicationId(value = "selected"),
        formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
        catalog = CatalogGeneration("catalog").toSkir(),
        implementationToken = "implementation",
        outputs =
            listOf(
                PublishedOutput(
                    reference =
                        CompiledArtifactReference(
                            root = artifact.root,
                            formatRevision = artifact.formatRevision,
                            mediaType = artifact.mediaType,
                            semanticDigest = artifact.semanticDigest.value,
                        ),
                    blob = CompiledBlobPointer(digest = ContentDigest("2".repeat(64)).value, size = 1),
                ),
            ),
    )
