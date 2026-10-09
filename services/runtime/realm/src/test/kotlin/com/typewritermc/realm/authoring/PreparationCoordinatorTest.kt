package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.types.DataValue
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.runTest
import java.util.concurrent.atomic.AtomicInteger

val PreparationCoordinatorTestSuite by testSuite {
    test("each preparation evaluates defaults independently") {
        runTest {
            val evaluations = AtomicInteger()
            val release = CompletableDeferred<Unit>()
            val coordinator =
                PreparationCoordinator(
                    catalog = { TestCatalogLease(CATALOG) },
                    evaluator =
                        PreparationEvaluator { _, _ ->
                            val value = evaluations.incrementAndGet()
                            release.await()
                            prepared(value.toString())
                        },
                )
            val request = request("shared")
            val callers = List(12) { async { coordinator.prepare(request) } }
            release.complete(Unit)
            val results = callers.awaitAll()
            assertEquals(12, results.toSet().size)
            assertEquals(12, evaluations.get())
            assertEquals(prepared("13"), coordinator.prepare(request))
        }
    }
    test("changed supplied values are evaluated without a request registry") {
        runTest {
            val coordinator =
                PreparationCoordinator(
                    catalog = { TestCatalogLease(CATALOG) },
                    evaluator =
                        PreparationEvaluator { request, _ ->
                            val supplied = (request.supplied as DataValue.Record).fields
                            val seed = supplied.getValue("seed") as DataValue.StringValue
                            prepared(seed.value)
                        },
                )
            assertEquals(prepared("first"), coordinator.prepare(request("shared", "first")))
            assertEquals(prepared("second"), coordinator.prepare(request("shared", "second")))
        }
    }
    test("an old request is rejected after catalog replacement") {
        runTest {
            var generation = CATALOG
            val coordinator =
                PreparationCoordinator(
                    catalog = { TestCatalogLease(generation) },
                    evaluator = PreparationEvaluator { _, _ -> prepared("captured") },
                )
            val request = request("completed")
            assertEquals(prepared("captured"), coordinator.prepare(request))
            generation = CatalogGeneration("next")
            assertEquals(generation, assertFailsWith<PreparationCatalogChanged> { coordinator.prepare(request) }.actual)
        }
    }
}

private fun request(
    id: String,
    supplied: String = "seed",
) = InitializationRequest(
    id = InitializationRequestId(id),
    catalog = CATALOG,
    target =
        PreparationTarget.Record(
            TypeSelection.Pending(CREATION_TYPE, listOf(ArgumentSelection.Unfilled)),
        ),
    supplied = DataValue.Record(mapOf("seed" to DataValue.StringValue(supplied))),
    intentHash = "client supplied hash",
)

private fun prepared(value: String) =
    PreparedValue(
        PreparedContent.Record(
            AuthoringRecord(
                configuration = TypeSelection.Pending(CREATION_TYPE, listOf(ArgumentSelection.Unfilled)),
                fields = mapOf("value" to DataValue.StringValue(value)),
            ),
        ),
        emptyList(),
    )

private val CATALOG = CatalogGeneration("catalog")
private val CREATION_TYPE = TypeDefinitionId(TypeId.Qualified("creation", "value"), 1)
