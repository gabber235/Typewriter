package com.typewritermc.realm.publication

import com.typewritermc.engine.ContentDigest
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationChange
import skirout.editor.v1.publication.RemovedRoot
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.PublicationId

val PublicationComparisonTest by testSuite {
    test("publication identity catalog provenance input fingerprints and blob pointers are not runtime changes") {
        val artifact = compiledArtifact()
        val selected = publishedContent(listOf(artifact))
        val candidate = artifact.copy(inputFingerprint = ContentDigest("c".repeat(64)))
        PublicationComparison.between(
            selected.copy(publication = PublicationId(value = "other"), catalog = CatalogGeneration(value = "other")),
            listOf(candidate),
            testEngineInputs(),
            published = { null },
        ) shouldBe
            PublicationComparison.Unchanged
    }
    test("format media and semantic digest changes each update the root") {
        val original = compiledArtifact()
        val selected = publishedContent(listOf(original))
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
                    published = { null },
                ).shouldBeInstanceOf<PublicationComparison.Changed>()
                .delta.allChanges shouldBe
                listOf(PublicationChange.RootUpdatedWrapper(original.root))
        }
    }
    test("token changes are meaningful even with no roots") {
        val selected = publishedContent(listOf(compiledArtifact())).copy(outputs = emptyList())
        PublicationComparison
            .between(
                selected,
                emptyList(),
                EngineImplementationInputs(
                    token =
                        skirout.editor.v1.type_catalog
                            .InputToken(value = "new"),
                ),
                published = { null },
            ).shouldBeInstanceOf<PublicationComparison.Changed>()
            .delta.allChanges shouldBe
            listOf(PublicationChange.REQUIREMENTS_CHANGED)
        PublicationComparison.between(null, emptyList(), testEngineInputs(), published = { null }) shouldBe PublicationComparison.Unchanged
    }
    test("old envelope format requires explicit publication even without changed output") {
        val artifact = compiledArtifact()
        for (outputs in listOf(publishedContent(listOf(artifact)), publishedContent(listOf(artifact)).copy(outputs = emptyList()))) {
            val candidate = if (outputs.outputs.isEmpty()) emptyList() else listOf(artifact)
            PublicationComparison
                .between(
                    outputs.copy(formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION + 1),
                    candidate,
                    testEngineInputs(),
                    published = { null },
                ).shouldBeInstanceOf<PublicationComparison.Changed>()
                .delta.allChanges shouldBe
                listOf(PublicationChange.REQUIREMENTS_CHANGED)
            PublicationComparison.between(outputs, candidate, testEngineInputs(), published = { null }) shouldBe
                PublicationComparison.Unchanged
        }
    }
    test("failed roots remain pending while definite removals and successful additions are comparable") {
        val old = compiledArtifact()
        val fresh = compiledArtifact(compilationRoot("fixture", "new"))
        val pending = compiledArtifact(compilationRoot("fixture", "pending")).root
        PublicationComparison.confirmedChanges(
            publishedContent(listOf(old)),
            listOf(fresh),
            setOf(fresh.root, pending),
            testEngineInputs(),
            published = { null },
        ) shouldBe
            listOf(
                PublicationChange.RootAddedWrapper(fresh.root),
                PublicationChange.RootRemovedWrapper(RemovedRoot(root = old.root, published = null)),
            )
    }
    test("a release delta without changes is refused") {
        shouldThrow<IllegalArgumentException> { publicationDelta(emptyList()) }.message shouldBe
            "A publication delta needs at least one change."
    }
    test("a release delta that lists one change twice is refused") {
        shouldThrow<IllegalArgumentException> {
            publicationDelta(listOf(PublicationChange.REQUIREMENTS_CHANGED, PublicationChange.REQUIREMENTS_CHANGED))
        }.message shouldBe "Publication delta changes must be distinct."
    }
}
