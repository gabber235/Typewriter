package com.typewritermc.realm.compiler

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputToken
import com.typewritermc.engine.*
import com.typewritermc.scripting.RuntimeMemberId
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

val PublicationComparisonTest by testSuite {
    test("publication identity catalog provenance input fingerprints and blob pointers are not runtime changes") {
        val artifact = comparisonArtifact()
        val selected = comparisonSelected(artifact)
        val candidate = artifact.copy(inputFingerprint = ContentDigest("c".repeat(64)))
        PublicationComparison.between(selected.copy(publication = PublicationId("other"), catalog = CatalogGeneration("other")), listOf(candidate), testEngineInputs()) shouldBe PublicationComparison.Unchanged
    }
    test("format media and semantic digest changes each update the root") {
        val original = comparisonArtifact()
        val selected = comparisonSelected(original)
        listOf(original.copy(formatRevision = 3), original.copy(mediaType = "application/other"), original.copy(semanticDigest = ContentDigest("b".repeat(64)))).forEach { artifact ->
            PublicationComparison.between(selected, listOf(artifact), testEngineInputs()).shouldBeInstanceOf<PublicationComparison.Changed>().delta.allChanges shouldBe listOf(PublicationChange.RootUpdated(original.root))
        }
    }
    test("token and signature changes are meaningful even with no roots") {
        val selected = comparisonSelected(comparisonArtifact()).copy(outputs = emptyList())
        val signature = RuntimeMemberSignature(RuntimeMemberId("fixture.member"), null, emptyList(), TypeUse.Scalar(ScalarKind.Text), emptySet())
        listOf(EngineImplementationInputs(emptySet(), InputToken("new")), EngineImplementationInputs(setOf(signature), InputToken("implementation"))).forEach { engine ->
            PublicationComparison.between(selected, emptyList(), engine).shouldBeInstanceOf<PublicationComparison.Changed>().delta.allChanges shouldBe listOf(PublicationChange.RequirementsChanged)
        }
        PublicationComparison.between(null, emptyList(), testEngineInputs()) shouldBe PublicationComparison.Unchanged
    }
    test("failed roots remain pending while definite removals and successful additions are comparable") {
        val old = comparisonArtifact()
        val fresh = comparisonArtifact("new")
        val pending = comparisonArtifact("pending").root
        PublicationComparison.confirmedChanges(comparisonSelected(old), listOf(fresh), setOf(fresh.root, pending), testEngineInputs()) shouldBe listOf(PublicationChange.RootAdded(fresh.root), PublicationChange.RootRemoved(old.root))
    }
}

private fun comparisonArtifact(id: String = "root") = CompiledArtifact(
    CompilationRoot(CompilationProjectionId("fixture"), ResourceId(id)), 2, "application/fixture",
    ContentDigest("1".repeat(64)), ContentDigest("a".repeat(64)), byteArrayOf(1),
)

private fun comparisonSelected(artifact: CompiledArtifact) = PublishedContent(
    PublicationId("selected"), 2, CatalogGeneration("catalog"), "implementation", emptySet(),
    listOf(PublishedOutput(CompiledArtifactReference(artifact.root, artifact.formatRevision, artifact.mediaType, artifact.semanticDigest), CompiledBlobPointer(ContentDigest("2".repeat(64)), 1))),
)
