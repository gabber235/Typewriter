package com.typewritermc.realm.operation

import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.types.fieldMap
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.catalog.PreparationOperation
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.type_catalog.DataValue
import java.util.concurrent.atomic.AtomicInteger

val PreparationCoordinatorTestSuite by testSuite {
    test("concurrent identical preparations each get their own evaluated result") {
        runTest {
            RealmFixture.core().use { realm ->
                val evaluations = AtomicInteger()
                val release = CompletableDeferred<Unit>()
                val coordinator =
                    realm.preparations { _, _ ->
                        val value = evaluations.incrementAndGet()
                        release.await()
                        PrepareValueResult.ReadyWrapper(prepared(value.toString()))
                    }
                val request = request(realm.generation)
                val callers = List(12) { async { coordinator.prepare(request) } }
                release.complete(Unit)
                val results = callers.awaitAll()
                results.toSet().size shouldBe 12
            }
        }
    }
    test("changed supplied values are independently evaluated") {
        runTest {
            RealmFixture.core().use { realm ->
                val coordinator =
                    realm.preparations { request, _ ->
                        val supplied =
                            ((request as PreparationOperation.StartWrapper).value.suppliedValue as DataValue.RecordWrapper)
                                .value.fieldMap
                        val seed = supplied.getValue("seed") as DataValue.StringValueWrapper
                        PrepareValueResult.ReadyWrapper(prepared(seed.value))
                    }
                coordinator.prepare(request(realm.generation, "first")) shouldBe prepared("first")
                coordinator.prepare(request(realm.generation, "second")) shouldBe prepared("second")
            }
        }
    }
    test("an old request is rejected after catalog replacement") {
        runTest {
            RealmFixture.core().use { realm ->
                val coordinator = realm.preparations { _, _ -> PrepareValueResult.ReadyWrapper(prepared("captured")) }
                val request = request(realm.generation)
                coordinator.prepare(request) shouldBe prepared("captured")
                realm.restart()
                shouldThrow<PreparationCatalogChanged> { coordinator.prepare(request) }.actual shouldBe realm.generation
            }
        }
    }
}
