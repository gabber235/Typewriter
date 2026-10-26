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
import java.util.concurrent.FutureTask
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

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
    test("a read context resumes its original view while retained and is refused once released") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to original)))
        val lease = store.capture()
        val context = lease.root.readContext
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story")))))

        store.retain(context).use { it.root.resources[id] } shouldBe original
        lease.close()

        shouldThrow<IllegalArgumentException> { store.retain(context) }.message shouldBe "The original read view is no longer retained."
        store.close()
    }
    test("a failed reload serves no stale current state, keeps retained reads and succeeds on the next capture") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to original)))
        val retained = store.capture()
        var fail = true
        store.invalidate {
            if (fail) error("storage unavailable")
            AuthoringSeed(mapOf(id to record(name = "Story")))
        }

        shouldThrow<IllegalStateException> { store.capture() }.message shouldBe "storage unavailable"
        retained.root.resources[id] shouldBe original
        fail = false
        store.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
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
    test("a captured view keeps the seed it was given when the caller changes it afterwards") {
        val id = ResourceId(value = "page")
        val arguments = mutableListOf<TypeUse>(INT_USE)
        val items = mutableListOf(ListItem(id = ItemId(value = "root"), value = DataValue.integer(BigInteger.ONE)))
        val fields =
            mutableMapOf<String, DataValue>(
                "name" to DataValue.StringValueWrapper("Quest"),
                "count" to DataValue.integer(BigInteger.ONE),
                "numbers" to DataValue.named(LIST_TYPE.namedUse(arguments), DataValue.listValue(items)),
            )
        val seed = mutableMapOf(id to AuthoringRecord.of(TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()), fields))
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(seed))

        seed.clear()
        fields["name"] = DataValue.StringValueWrapper("Changed")
        arguments += TEXT_USE
        items += ListItem(id = ItemId(value = "late"), value = DataValue.integer(BigInteger.TWO))

        store.capture().use { lease ->
            val captured = lease.root.resources.getValue(id)
            captured.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("Quest")
            val numbers = captured.fieldMap.getValue("numbers") as DataValue.NamedWrapper
            numbers.actualType.arguments shouldBe listOf(INT_USE)
            (numbers.payload as DataValue.ListValueWrapper).items.map(ListItem::id) shouldBe listOf(ItemId(value = "root"))
        }
        store.close()
    }
    test("a staged view keeps the upserts it was given when the caller changes them afterwards") {
        val id = ResourceId(value = "page")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to record(name = "Quest"))))
        store.capture().use { lease ->
            val items = mutableListOf(ListItem(id = ItemId(value = "staged"), value = DataValue.integer(BigInteger.TWO)))
            val fields =
                mutableMapOf<String, DataValue>(
                    "name" to DataValue.StringValueWrapper("Story"),
                    "count" to DataValue.integer(BigInteger.TWO),
                    "numbers" to DataValue.named(LIST_USE, DataValue.listValue(items)),
                )
            val upserts = mutableMapOf(id to AuthoringRecord.of(TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()), fields))
            val staged = lease.stagedView(upserts)

            upserts.clear()
            fields["name"] = DataValue.StringValueWrapper("Changed")
            items.clear()

            val kept = staged.resources.getValue(id)
            kept.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("Story")
            val numbers = kept.fieldMap.getValue("numbers") as DataValue.NamedWrapper
            (numbers.payload as DataValue.ListValueWrapper).items.map(ListItem::id) shouldBe listOf(ItemId(value = "staged"))
        }
        store.close()
    }
    test("an install waits until a current read in progress has finished") {
        val id = ResourceId(value = "page")
        val store = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(id to record(name = "Quest"))))
        val next = store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story"))))
        val executor = Executors.newFixedThreadPool(2)
        val reading = CountDownLatch(1)
        val installing = CountDownLatch(1)
        val installation =
            FutureTask {
                installing.countDown()
                store.install(next)
            }
        try {
            val read =
                executor.submit<Pair<Boolean, AuthoringRecord?>> {
                    store.read {
                        reading.countDown()
                        installing.await(2, TimeUnit.SECONDS)
                        // While this read runs, the install another thread started cannot finish, so the current state
                        // read again on this thread is still the one the read began with.
                        val installed =
                            runCatching { installation.get(200, TimeUnit.MILLISECONDS) }.exceptionOrNull() !is TimeoutException
                        installed to store.read { current -> current.resources[id] }
                    }
                }
            reading.await(2, TimeUnit.SECONDS) shouldBe true
            executor.execute(installation)

            read.get(5, TimeUnit.SECONDS) shouldBe (false to record(name = "Quest"))
            installation.get(2, TimeUnit.SECONDS)
            store.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
        } finally {
            executor.shutdownNow()
            store.close()
        }
    }
}
