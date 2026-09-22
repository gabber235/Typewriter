package com.typewritermc.realm.routes

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.repository.AuthoringBatch
import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringChanged
import com.typewritermc.realm.repository.AuthoringGraphSnapshot
import com.typewritermc.realm.repository.AuthoringOperation
import com.typewritermc.realm.repository.AuthoringPreviewResult
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.realm.repository.GraphSelectionResult
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.ApplyAuthoringBatchRequest
import skirout.editor.v1.authoring.ApplyAuthoringBatchResponse
import skirout.editor.v1.authoring.RelationId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.authoring.AuthoringOperation as WireAuthoringOperation
import skirout.editor.v1.type_catalog.ResourceId as WireResourceId

val AuthoringRoutesTest by testSuite {
    test("search compatibility is taken only from the constrained selection") {
        val compatible = ResourceId("compatible")
        val reintroduced = ResourceId("reintroduced")
        val snapshot =
            AuthoringGraphSnapshot(
                generation = "generation",
                sequence = 1,
                resources = emptyList(),
                edges = emptyList(),
                selections =
                    listOf(
                        GraphSelectionResult("search", listOf(compatible), emptyList(), emptyList()),
                        GraphSelectionResult("search-presentation", listOf(reintroduced), emptyList(), emptyList()),
                    ),
            )

        snapshot.compatibleSearchCandidateIds().shouldContainExactly(compatible)
    }

    test("committed changes invalidate compilation after publication failure") {
        runTest {
            val root = CompilationRoot(CompilationProjectionId("test.projection"), ResourceId("root"))
            val invalidations = mutableListOf<List<CompilationRoot>>()
            val repository = AppliedAuthoringRepository(root)

            RouteFixture(
                authoring = repository,
                onCompilationInvalidated = invalidations::add,
            ).use { fixture ->
                fixture.transport.failNextPublish(TransportError.Unavailable())

                val response =
                    fixture.request(
                        "editor.authoring.batch.apply",
                        ApplyAuthoringBatchRequest(
                            batchId = "batch",
                            generation = CatalogGeneration(value = "generation"),
                            operations =
                                listOf(
                                    WireAuthoringOperation.createDeclareRelation(
                                        relation = RelationId(value = "11111111111111111111111111111111"),
                                        source = WireResourceId(value = "source"),
                                        target = WireResourceId(value = "target"),
                                    ),
                                ),
                        ),
                        ApplyAuthoringBatchRequest.serializer,
                        ApplyAuthoringBatchResponse.serializer,
                    )

                response.shouldBeInstanceOf<ApplyAuthoringBatchResponse.AppliedWrapper>()
                invalidations shouldBe listOf(listOf(root))
            }
        }
    }
}

private class AppliedAuthoringRepository(
    private val root: CompilationRoot,
) : AuthoringRepository {
    override suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult =
        AuthoringBatchResult.Applied(
            AuthoringChanged(
                generation = batch.generation,
                sequence = 1,
                batchId = BatchId(batch.id.value),
                resources = emptyList(),
                edges = emptyList(),
                compilationImpact = listOf(root),
            ),
        )

    override suspend fun preview(
        generation: String,
        operations: List<AuthoringOperation>,
    ): AuthoringPreviewResult = AuthoringPreviewResult.Invalid(emptyList())
}
