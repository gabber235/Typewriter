package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.PreparedCreation
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

class CreationCoordinatorTest {
    fun concurrentReplayUsesOneCapturedResultAcrossFlightCleanup() =
        runTest {
            val receipts = RecordingReceiptStore()
            val evaluations = AtomicInteger()
            val entered = CompletableDeferred<Unit>()
            val release = CompletableDeferred<Unit>()
            val result = prepared("winner")
            val coordinator =
                CreationCoordinator(
                    catalog = { TestCatalogLease(CATALOG) },
                    receipts = receipts,
                    evaluator =
                        CreationEvaluator { _, _ ->
                            evaluations.incrementAndGet()
                            entered.complete(Unit)
                            release.await()
                            result
                        },
                )
            val request = request("shared")
            val callers = List(12) { async { coordinator.prepare(request) } }
            entered.await()
            val aroundCompletion = async { coordinator.prepare(request) }
            release.complete(Unit)

            val results = callers.awaitAll() + aroundCompletion.await()

            assertEquals(List(13) { result }, results)
            assertEquals(1, evaluations.get())
            assertEquals(result, coordinator.prepare(request))
            assertEquals(1, evaluations.get())
        }

    fun sameRequestAndClientHashRejectChangedSuppliedPayload() =
        runTest {
            val coordinator =
                CreationCoordinator(
                    catalog = { TestCatalogLease(CATALOG) },
                    receipts = RecordingReceiptStore(),
                    evaluator =
                        CreationEvaluator { request, _ ->
                            prepared((request.supplied.getValue("seed") as DataValue.StringValue).value)
                        },
                )
            val original = request("forged", "first")
            val changed = request("forged", "second")

            coordinator.prepare(original)

            assertFailsWith<IllegalArgumentException> { coordinator.prepare(changed) }
        }

    fun completedReceiptReplaysAfterCatalogChangeButFreshOldRequestIsRejected() =
        runTest {
            var generation = CATALOG
            val coordinator =
                CreationCoordinator(
                    catalog = { TestCatalogLease(generation) },
                    receipts = RecordingReceiptStore(),
                    evaluator = CreationEvaluator { _, _ -> prepared("captured") },
                )
            val completed = request("completed")
            val first = coordinator.prepare(completed)
            generation = CatalogGeneration("next")

            assertEquals(first, coordinator.prepare(completed))
            assertEquals(
                generation,
                assertFailsWith<CreationCatalogChanged> { coordinator.prepare(request("fresh")) }.actual,
            )
        }

    fun sameRequestRejectsChangedOperationSeed() =
        runTest {
            val coordinator =
                CreationCoordinator(
                    catalog = { TestCatalogLease(CATALOG) },
                    receipts = RecordingReceiptStore(),
                    evaluator = CreationEvaluator { _, _ -> prepared("captured") },
                )
            val original = request("operation")
            coordinator.prepare(original)

            assertFailsWith<IllegalArgumentException> {
                coordinator.prepare(original.copy(intentHash = "changed operation"))
            }
        }
}

private class RecordingReceiptStore : CreationReceiptStore {
    private val receipts = linkedMapOf<InitializationRequestId, CreationReceipt>()

    override fun completed(
        id: InitializationRequestId,
        intentDigest: String,
    ): PreparedCreation? =
        synchronized(receipts) {
            val receipt = receipts[id] ?: return@synchronized null
            require(receipt.intentDigest == intentDigest) { "Request identity was reused for another intent." }
            receipt.result
        }

    override fun save(receipt: CreationReceipt): PreparedCreation =
        synchronized(receipts) {
            val existing = receipts[receipt.request]
            if (existing != null) {
                require(existing.intentDigest == receipt.intentDigest) { "Request identity was reused for another intent." }
                existing.result
            } else {
                receipts[receipt.request] = receipt
                receipt.result
            }
        }
}

private fun request(
    id: String,
    supplied: String = "seed",
) = InitializationRequest(
    id = InitializationRequestId(id),
    catalog = CATALOG,
    type = TypeSelection.Pending(CREATION_TYPE, listOf(ArgumentSelection.Unfilled)),
    supplied = mapOf("seed" to DataValue.StringValue(supplied)),
    intentHash = "client supplied hash",
)

private fun prepared(value: String) =
    PreparedCreation(
        AuthoringRecord(
            configuration = TypeSelection.Pending(CREATION_TYPE, listOf(ArgumentSelection.Unfilled)),
            fields = mapOf("value" to DataValue.StringValue(value)),
        ),
        emptyList(),
    )

private val CATALOG = CatalogGeneration("catalog")
private val CREATION_TYPE = TypeDefinitionId(TypeId.Qualified("creation", "value"), 1)

val CreationCoordinatorTestSuite by testSuite {
    test("concurrentReplayUsesOneCapturedResultAcrossFlightCleanup") {
        CreationCoordinatorTest().concurrentReplayUsesOneCapturedResultAcrossFlightCleanup()
    }
    test("sameRequestAndClientHashRejectChangedSuppliedPayload") {
        CreationCoordinatorTest().sameRequestAndClientHashRejectChangedSuppliedPayload()
    }
    test("completedReceiptReplaysAfterCatalogChangeButFreshOldRequestIsRejected") {
        CreationCoordinatorTest().completedReceiptReplaysAfterCatalogChangeButFreshOldRequestIsRejected()
    }
    test("sameRequestRejectsChangedOperationSeed") {
        CreationCoordinatorTest().sameRequestRejectsChangedOperationSeed()
    }
}
