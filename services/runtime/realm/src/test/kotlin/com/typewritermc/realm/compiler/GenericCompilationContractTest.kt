package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.ContentDigest
import com.typewritermc.library.Page
import com.typewritermc.realm.CoreResourceDefinitionIds
import com.typewritermc.realm.repository.AuthoringGraphDelta
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.loadTestPrototypes
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val GenericCompilationContractTest by testSuite {
    test("manifest identity is projection neutral") {
        val root = CompilationRoot(CompilationProjectionId("test.opaque"), ResourceId("root"))
        val reference =
            CompiledArtifactReference(
                root = root,
                formatRevision = 1,
                mediaType = "application/vnd.typewriter.opaque",
                semanticDigest = digest('a'),
            )
        val manifest =
            CompiledArtifactManifest(
                formatRevision = 1,
                digest = digest('b'),
                sourceRevision = "1",
                catalogRevision = "1",
                artifacts = listOf(reference),
            )

        manifest.artifacts.single().root shouldBe root
        manifest.artifacts.single().mediaType shouldBe "application/vnd.typewriter.opaque"
    }

    test("duplicate roots are rejected before publication") {
        val root = CompilationRoot(CompilationProjectionId("test.opaque"), ResourceId("root"))
        val reference =
            CompiledArtifactReference(root, 1, "application/vnd.typewriter.opaque", digest('a'))

        shouldThrow<IllegalArgumentException> {
            CompiledArtifactManifest(
                formatRevision = 1,
                digest = digest('b'),
                sourceRevision = "1",
                catalogRevision = "1",
                artifacts = listOf(reference, reference),
            )
        }
    }

    test("registered projection impact is isolated by projection id") {
        val root = ResourceId("root")
        val projection =
            object : AuthoringCompilationProjection {
                override val id = CompilationProjectionId("test.opaque")
                override val root = TypeExpression.Any
                override val graphRequirement = GraphReadRequirement()

                override fun affectedRoots(
                    change: AuthoringGraphDelta,
                    before: AuthoringWorkingGraph,
                    proposed: AuthoringWorkingGraph,
                ) = setOf(root)

                override suspend fun compile(
                    root: ResourceId,
                    graph: AuthoringWorkingGraph,
                ): CompilationResult =
                    CompilationResult.Success(
                        CompiledArtifact(
                            CompilationRoot(id, root),
                            1,
                            "application/vnd.typewriter.opaque",
                            digest('a'),
                            digest('b'),
                            byteArrayOf(1, 2, 3),
                        ),
                    )
            }
        val registry = AuthoringCompilationProjectionRegistry(listOf(projection))
        val empty = AuthoringWorkingGraph(emptyMap(), emptyMap())
        val impact = registry.impact(AuthoringGraphDelta(emptyMap(), emptySet(), emptySet(), emptyMap(), emptySet()), empty, empty)

        impact.rootsFor(CompilationProjectionId("test.opaque")) shouldBe setOf(root)
        impact.rootsFor(CompilationProjectionId("other")) shouldBe emptySet()
    }

    test("Page compilation advertises the concrete Page root type") {
        val prototypes = loadTestPrototypes()
        val projection = PageCompilationProjection(emptySet(), catalogRevision = { "test" })

        projection.root shouldBe TypeExpression.Named(com.typewritermc.library.PAGE_CONTRACT_TYPE)
        projection.graphRequirement.definitions shouldBe
            setOf(CoreResourceDefinitionIds.PAGE, CoreResourceDefinitionIds.ELEMENT, CoreResourceDefinitionIds.CUE)
    }
}

private fun digest(character: Char) = ContentDigest(character.toString().repeat(64))
