@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.realm.operation.operationObservation
import com.typewritermc.types.actualType
import com.typewritermc.types.integer
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigInteger
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

val AuthoringViewStoreTest by testSuite {
    test("operation overlays require the exact saved observation and preserve saved state") {
        val id = ResourceId(value = "operation-page")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to record(name = "Saved"))))
        try {
            val token =
                store.capture().use { saved ->
                    val working = saved.operationObservation(saved.root.observationId, mapOf(id to record(name = "Draft")), emptySet())
                    (
                        working.resources
                            .getValue(id)
                            .fieldMap
                            .getValue("name") as DataValue.StringValueWrapper
                    ).value shouldBe "Draft"
                    (
                        saved.root.resources
                            .getValue(id)
                            .fieldMap
                            .getValue("name") as DataValue.StringValueWrapper
                    ).value shouldBe "Saved"
                    saved.root.observationId
                }
            store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Other panel")))))
            store.capture().use { next ->
                (next.root.observationId != token) shouldBe true
                shouldThrow<com.typewritermc.realm.operation.StaleOperationObservation> {
                    next.operationObservation(token, mapOf(id to record(name = "Draft")), emptySet())
                }
            }
        } finally {
            store.close()
        }
    }
    test("retained views preserve original values while new reads see installed state") {
        val catalog = TestCatalogLease()
        val id = ResourceId(value = "page")
        val original = record(name = "Quest", numbers = listOf("a" to 1, "b" to 2))
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to original)))
        val retained = store.capture()
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story", numbers = listOf("b" to 2, "a" to 1))))))
        retained.root.resources[id] shouldBe original
        store.capture().use {
            CapturedAuthoringReads(it.originalView()).read(boundPath<String>(location(id, "name"), TEXT_USE)).available()
        } shouldBe "Story"
        CapturedAuthoringReads(retained.originalView()).members(boundCollectionPath(location(id, "numbers"))) shouldBe
            listOf(ItemId(value = "a"), ItemId(value = "b"))
        retained.close()
        store.close()
        catalog.openCount shouldBe 0
    }
    test("read contexts belong to one retained original view") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(emptyMap()))
        val original = store.capture()
        val context = original.root.readContext
        store.install(store.prepare(AuthoringViewDelta()))
        store.retain(context).use { (it.root === original.root) shouldBe true }
        original.close()
        shouldThrow<IllegalArgumentException> { store.retain(context) }
        store.close()
    }
    test("reload failure prevents serving old current state but preserves retained reads") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest")
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to original)))
        val retained = store.capture()
        var fail = true
        var loads = 0
        store.invalidate {
            loads++
            if (fail) error("storage unavailable")
            AuthoringSeed(mapOf(id to record(name = "Story")))
        }
        shouldThrow<IllegalStateException> { store.capture() }
        retained.root.resources[id] shouldBe original
        fail = false
        store.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
        loads shouldBe 2
        store.capture().close()
        loads shouldBe 2
        retained.close()
        store.close()
    }
    test("staged reads keep expectations from the original baseline") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to original)))
        store.capture().use { lease ->
            val reads = CapturedAuthoringReads(lease.stagedView(mapOf(id to record(name = "Story"))))
            reads.read(boundPath<String>(location(id, "name"), TEXT_USE)).available() shouldBe "Story"
            val expected =
                reads.observations().filterIsInstance<skirout.editor.v1.authoring_facts.EditExpectation.ValueWrapper>().single {
                    it.value.at ==
                        location(id, "name")
                }
            expected.value.expected shouldBe DataValue.StringValueWrapper("Quest")
        }
        store.close()
    }
    test("root and staged views reject caller and exposed collection mutation") {
        val id = ResourceId(value = "page")
        val rootArguments = mutableListOf<TypeUse>(INT_USE)
        val rootItems = mutableListOf(ListItem(id = ItemId(value = "root"), value = DataValue.integer(BigInteger.ONE)))
        val rootFields =
            mutableMapOf<String, DataValue>(
                "name" to DataValue.StringValueWrapper("Quest"),
                "count" to DataValue.integer(BigInteger.ONE),
                "numbers" to DataValue.named(LIST_TYPE.namedUse(rootArguments), DataValue.listValue(rootItems)),
            )
        val seed = mutableMapOf(id to AuthoringRecord.of(TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()), rootFields))
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(seed))

        seed.clear()
        rootFields["name"] = DataValue.StringValueWrapper("Changed")
        rootArguments += TEXT_USE
        rootItems += ListItem(id = ItemId(value = "late"), value = DataValue.integer(BigInteger.TWO))

        store.capture().use { lease ->
            val retained = lease.root.resources.getValue(id)
            retained.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("Quest")
            val retainedNumbers = retained.fieldMap.getValue("numbers") as DataValue.NamedWrapper
            retainedNumbers.actualType.arguments shouldBe listOf(INT_USE)
            (retainedNumbers.payload as DataValue.ListValueWrapper).items.map(ListItem::id) shouldBe listOf(ItemId(value = "root"))
            shouldThrow<UnsupportedOperationException> {
                @Suppress("UNCHECKED_CAST")
                (lease.root.resources as MutableMap<ResourceId, AuthoringRecord>)[ResourceId(value = "other")] = retained
            }
            // Skir type values are deeply immutable: their lists are not mutable lists at all.
            (retainedNumbers.actualType.arguments is MutableList<*>) shouldBe false

            val stagedItems = mutableListOf(ListItem(id = ItemId(value = "staged"), value = DataValue.integer(BigInteger.TWO)))
            val stagedFields =
                mutableMapOf<String, DataValue>(
                    "name" to DataValue.StringValueWrapper("Story"),
                    "count" to DataValue.integer(BigInteger.TWO),
                    "numbers" to DataValue.named(LIST_USE, DataValue.listValue(stagedItems)),
                )
            val upserts = mutableMapOf(id to AuthoringRecord.of(TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()), stagedFields))
            val staged = lease.stagedView(upserts)
            upserts.clear()
            stagedFields["name"] = DataValue.StringValueWrapper("Changed")
            stagedItems.clear()

            val retainedStaged = staged.resources.getValue(id)
            retainedStaged.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("Story")
            val stagedNumbers = retainedStaged.fieldMap.getValue("numbers") as DataValue.NamedWrapper
            (stagedNumbers.payload as DataValue.ListValueWrapper).items.map(ListItem::id) shouldBe listOf(ItemId(value = "staged"))
            // Skir data values are deeply immutable as well.
            ((stagedNumbers.payload as DataValue.ListValueWrapper).items is MutableList<*>) shouldBe false
        }
        store.close()
    }
    test("installation and current reads share one lock") {
        val id = ResourceId(value = "page")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to record(name = "Quest"))))
        val executor = Executors.newFixedThreadPool(2)
        val reading = CountDownLatch(1)
        val release = CountDownLatch(1)
        try {
            val read =
                executor.submit {
                    store.read { current ->
                        reading.countDown()
                        release.await()
                        current.resources[id] shouldBe record(name = "Quest")
                    }
                }
            reading.await(2, TimeUnit.SECONDS) shouldBe true
            val write = executor.submit { store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story"))))) }
            write.isDone shouldBe false
            release.countDown()
            read.get(2, TimeUnit.SECONDS)
            write.get(2, TimeUnit.SECONDS)
            store.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
        } finally {
            release.countDown()
            executor.shutdownNow()
            store.close()
        }
    }
}
