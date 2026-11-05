@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.authoring

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.realm.checking.rename
import com.typewritermc.realm.edit.MemoryAuthoringStorage
import com.typewritermc.realm.operation.operationObservation
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.openCatalogLeases
import com.typewritermc.realm.testing.shouldBeCommitted
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
import kotlinx.coroutines.runBlocking
import skirout.editor.v1.authoring.EditIntent
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
        RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), mapOf(id to record(name = "Saved"))).use { realm ->
            val token =
                realm.views.capture().use { saved ->
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
            realm.commit(rename(id, "Other panel")).shouldBeCommitted()
            realm.views.capture().use { next ->
                (next.root.observationId != token) shouldBe true
                shouldThrow<com.typewritermc.realm.operation.StaleOperationObservation> {
                    next.operationObservation(token, mapOf(id to record(name = "Draft")), emptySet())
                }
            }
        }
    }
    test("retained views preserve original values while new reads see installed state") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest", numbers = listOf("a" to 1, "b" to 2))
        val realm = RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), mapOf(id to original))
        val openLeases = realm.openCatalogLeases()
        realm.use {
            val retained = realm.views.capture()
            realm
                .commit(
                    rename(id, "Story"),
                    EditIntent.createMove(at = location(id, "numbers"), item = ItemId(value = "a"), after = ItemId(value = "b")),
                ).shouldBeCommitted()
            retained.root.resources[id] shouldBe original
            realm.views.capture().use {
                CapturedAuthoringReads(it.originalView()).read(boundPath<String>(location(id, "name"), TEXT_USE)).available()
            } shouldBe "Story"
            CapturedAuthoringReads(retained.originalView()).members(boundCollectionPath(location(id, "numbers"))) shouldBe
                listOf(ItemId(value = "a"), ItemId(value = "b"))
            retained.close()
        }
        openLeases() shouldBe 0
    }
    test("a read context resumes its original view while retained and is refused once released") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest")
        RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), mapOf(id to original)).use { realm ->
            val lease = realm.views.capture()
            val context = lease.root.readContext
            realm.commit(rename(id, "Story")).shouldBeCommitted()

            realm.views.retain(context).use { it.root.resources[id] } shouldBe original
            lease.close()

            shouldThrow<IllegalArgumentException> { realm.views.retain(context) }.message shouldBe
                "The original read view is no longer retained."
        }
    }
    test("a failed reload serves no stale current state, keeps retained reads and succeeds on the next capture") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest")
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to original)))
        RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), storage = storage).use { realm ->
            realm.views.capture().use { retained ->
                // The commit saves but loses its result, so the Realm reloads saved authoring on the next read.
                storage.failAfterWrite = true
                shouldThrow<IllegalStateException> { realm.commit(rename(id, "Story")) }
                storage.failAfterWrite = false
                storage.failReads = true

                shouldThrow<IllegalStateException> { realm.views.capture() }.message shouldBe "read unavailable"
                retained.root.resources[id] shouldBe original
                storage.failReads = false
                realm.views.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
            }
        }
    }
    test("staged reads keep expectations from the original baseline") {
        val id = ResourceId(value = "page")
        val original = record(name = "Quest")
        captured(mapOf(id to original)) { lease ->
            val reads = CapturedAuthoringReads(lease.stagedView(mapOf(id to record(name = "Story"))))
            reads.read(boundPath<String>(location(id, "name"), TEXT_USE)).available() shouldBe "Story"
            val expected =
                reads.observations().filterIsInstance<skirout.editor.v1.authoring_facts.EditExpectation.ValueWrapper>().single {
                    it.value.at ==
                        location(id, "name")
                }
            expected.value.expected shouldBe DataValue.StringValueWrapper("Quest")
        }
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
        RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), seed).use { realm ->
            seed.clear()
            fields["name"] = DataValue.StringValueWrapper("Changed")
            arguments += TEXT_USE
            items += ListItem(id = ItemId(value = "late"), value = DataValue.integer(BigInteger.TWO))

            realm.views.capture().use { lease ->
                val captured = lease.root.resources.getValue(id)
                captured.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("Quest")
                val numbers = captured.fieldMap.getValue("numbers") as DataValue.NamedWrapper
                numbers.actualType.arguments shouldBe listOf(INT_USE)
                (numbers.payload as DataValue.ListValueWrapper).items.map(ListItem::id) shouldBe listOf(ItemId(value = "root"))
            }
        }
    }
    test("a staged view keeps the upserts it was given when the caller changes them afterwards") {
        val id = ResourceId(value = "page")
        captured(mapOf(id to record(name = "Quest"))) { lease ->
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
    }
    test("an install waits until a current read in progress has finished") {
        val id = ResourceId(value = "page")
        RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), mapOf(id to record(name = "Quest"))).use { realm ->
            val store = realm.views
            val executor = Executors.newFixedThreadPool(2)
            val reading = CountDownLatch(1)
            val installing = CountDownLatch(1)
            val installation =
                FutureTask {
                    installing.countDown()
                    runBlocking { realm.commit(rename(id, "Story")) }
                }
            try {
                val read =
                    executor.submit<Pair<Boolean, AuthoringRecord?>> {
                        store.read {
                            reading.countDown()
                            installing.await(2, TimeUnit.SECONDS)
                            // While this read runs, the commit another thread started cannot install, so the current
                            // state read again on this thread is still the one the read began with.
                            val installed =
                                runCatching { installation.get(200, TimeUnit.MILLISECONDS) }.exceptionOrNull() !is TimeoutException
                            installed to store.read { current -> current.resources[id] }
                        }
                    }
                reading.await(2, TimeUnit.SECONDS) shouldBe true
                executor.execute(installation)

                read.get(5, TimeUnit.SECONDS) shouldBe (false to record(name = "Quest"))
                installation.get(2, TimeUnit.SECONDS).shouldBeCommitted()
                store.capture().use { it.root.resources[id] } shouldBe record(name = "Story")
            } finally {
                executor.shutdownNow()
            }
        }
    }
}
