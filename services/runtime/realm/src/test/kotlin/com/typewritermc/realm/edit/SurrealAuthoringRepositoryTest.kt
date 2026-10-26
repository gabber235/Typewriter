package com.typewritermc.realm.edit

import com.surrealdb.Surreal
import com.typewritermc.authoring.CheckedWriteResult
import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.publication.AuthoringAcceptance
import com.typewritermc.realm.storage.MigrationResources
import com.typewritermc.realm.storage.openTestDatabase
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.linkOrNull
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.text
import com.typewritermc.realm.testing.value
import com.typewritermc.types.bytes
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.namedUse
import com.typewritermc.types.record
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigInteger

private val id = ResourceId(value = "quest")
private val initial = record(name = "Quest", count = 1)
private val title = location(id, "name")
private val catalog = DefinitionCatalog(TEST_DEFINITIONS)

/** A saved quest titled "Quest", in a Realm whose [storage] can fail on purpose. */
private suspend fun quest(storage: MemoryAuthoringStorage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))) =
    RealmFixture.of(catalog, storage.seed.resources, storage)

/** Renames the quest to [next], guarded on the title being [expected] in the catalog generation [catalog]. */
private fun rename(
    catalog: CatalogGeneration,
    expected: String = "Quest",
    next: String = "Story",
) = PreparedEdit(
    catalog = catalog,
    expectations =
        listOf(
            EditExpectation.createResourceExists(id = id, expected = true),
            EditExpectation.createConfiguration(at = ValueLocation.of(id), expected = initial.configuration),
            EditExpectation.createConfiguration(at = title, expected = null),
            EditExpectation.createValue(at = title, expected = DataValue.StringValueWrapper(expected)),
        ),
    intents = listOf(EditIntent.createSetValue(at = title, value = DataValue.StringValueWrapper(next))),
)

/** The facts as they were saved when the commit conflicted. */
private fun CommitPreparedEditResponse.conflictingFacts(): List<EditExpectation> =
    shouldBeInstanceOf<CommitPreparedEditResponse.ConflictErrorWrapper>().value.map { it.actual }

private fun savedTitle(text: String) = EditExpectation.createValue(at = title, expected = DataValue.StringValueWrapper(text))

val SurrealAuthoringRepositoryTest by testSuite {
    test("an edit guarded on the title commits without touching an unrelated field") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial.with("count", DataValue.integer(BigInteger.TWO)))))
        quest(storage).use { realm ->
            realm.commit(rename(realm.generation)).shouldBeCommitted()

            realm.resources.getValue(id).text("name") shouldBe "Story"
            realm.resources.getValue(id).value("count") shouldBe DataValue.integer(BigInteger.TWO)
        }
    }

    test("an edit whose expected title is stale conflicts on the title with its saved value and saves nothing") {
        quest().use { realm ->
            realm.commit(rename(realm.generation)).shouldBeCommitted()
            val saved = realm.resources

            realm.commit(rename(realm.generation, next = "Tale")).conflictingFacts() shouldBe listOf(savedTitle("Story"))
            realm.resources shouldBe saved
        }
    }

    test("ordered writes to one field in an edit are guarded once on the saved value and keep the last") {
        quest().use { realm ->
            val edits =
                rename(realm.generation).copy(
                    intents =
                        listOf(
                            "Q",
                            "Qu",
                            "Story",
                        ).map { EditIntent.createSetValue(at = title, value = DataValue.StringValueWrapper(it)) },
                )

            realm.commit(edits).shouldBeCommitted()

            realm.resources.getValue(id).text("name") shouldBe "Story"
        }
    }

    test("an edit guarded on a value it writes itself conflicts with the saved value and saves nothing") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        quest(storage).use { realm ->
            val edits =
                rename(realm.generation, expected = "Qu").copy(
                    intents =
                        listOf(
                            "Q",
                            "Qu",
                            "Story",
                        ).map { EditIntent.createSetValue(at = title, value = DataValue.StringValueWrapper(it)) },
                )

            realm.commit(edits).conflictingFacts() shouldBe listOf(savedTitle("Quest"))
            storage.seed.resources.getValue(id) shouldBe initial
        }
    }

    test("unfinished authoring content is saved but publication rejects it") {
        quest().use { realm ->
            realm
                .commit(rename(realm.generation).copy(intents = listOf(EditIntent.createSetValue(at = title, value = DataValue.UNFILLED))))
                .shouldBeCommitted()
            realm.restart()

            realm.resources.getValue(id).value("name") shouldBe DataValue.UNFILLED
            RealmCheckRuntime(realm.views).use { checks ->
                realm.views.capture().use { saved ->
                    AuthoringAcceptance(realm.views, checks).evaluate(saved).findings.map { it.code to it.primary } shouldBe
                        listOf("unfinished_value" to title)
                }
            }
        }
    }

    test("an unguarded write is rejected with missing_expectation and never saved") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        quest(storage).use { realm ->
            realm.commit(rename(realm.generation).copy(expectations = emptyList())).shouldBeRejected("missing_expectation")

            storage.seed.resources.getValue(id) shouldBe initial
        }
    }

    test("an edit prepared on the previous catalog is refused with the active generation once another catalog is activated") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        quest(storage).use { realm ->
            val previous = realm.generation
            val replacement = catalog.lease(CatalogGeneration(value = "replacement"))
            var installed = false
            var published = false
            realm.owner.activateCatalog(replacement, { installed = true }, { published = true })
            installed shouldBe true
            published shouldBe true

            realm.commit(rename(previous)) shouldBe CommitPreparedEditResponse.CatalogChangedErrorWrapper(replacement.generation)
            storage.seed.resources.getValue(id) shouldBe initial
        }
    }

    test("a commit whose result is lost reloads the saved state while an open lease keeps what it read") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        quest(storage).use { realm ->
            realm.views.capture().use { retained ->
                storage.failAfterWrite = true
                shouldThrow<IllegalStateException> { realm.commit(rename(realm.generation)) }
                storage.failAfterWrite = false
                storage.failReads = true
                shouldThrow<IllegalStateException> { realm.views.capture() }
                retained.root.resources[id] shouldBe initial
                storage.failReads = false

                realm.resources.getValue(id).text("name") shouldBe "Story"
                realm.commit(rename(realm.generation)).conflictingFacts() shouldBe listOf(savedTitle("Story"))
            }
        }
    }

    test("a failed write leaves the saved title unchanged and the retry commits") {
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        quest(storage).use { realm ->
            storage.failBeforeWrite = true
            shouldThrow<IllegalStateException> { realm.commit(rename(realm.generation)) }
            storage.failBeforeWrite = false

            realm.resources.getValue(id).text("name") shouldBe "Quest"
            realm.commit(rename(realm.generation)).shouldBeCommitted()
            realm.resources.getValue(id).text("name") shouldBe "Story"
        }
    }

    test("of two concurrent edits guarded on the same title exactly one commits") {
        quest().use { realm ->
            val names = List(8) { "Story $it" }
            val results =
                coroutineScope {
                    names.map { name -> async(Dispatchers.Default) { realm.commit(rename(realm.generation, next = name)) } }.awaitAll()
                }

            val committed = names.filterIndexed { index, _ -> results[index] == CommitPreparedEditResponse.COMMITTED }
            committed.size shouldBe 1
            results.filter { it != CommitPreparedEditResponse.COMMITTED }.forEach {
                it.conflictingFacts() shouldBe
                    listOf(savedTitle(committed.single()))
            }
            realm.resources.getValue(id).text("name") shouldBe committed.single()
        }
    }

    test("an operation write to a resource that does not exist is reported as operation_write_rejected at that location") {
        quest().use { realm ->
            val missing = location(ResourceId(value = "missing"), "name")
            realm.views.capture().use { lease ->
                WorkingViewEditContext(lease.root, "operation").checkedSet(missing, DataValue.StringValueWrapper("Story")) shouldBe
                    CheckedWriteResult.Rejected(listOf(ValueProblem(location = missing, code = "operation_write_rejected")))
            }
            realm.resources.getValue(id) shouldBe initial
        }
    }

    test("a deleted resource is removed from Surreal and stays gone after a reload") {
        RealmFixture.surreal(catalog).use { realm ->
            val kept = ResourceId(value = "kept")
            realm
                .commit(
                    EditIntent.createCreateResource(id = id, record = initial),
                    EditIntent.createCreateResource(id = kept, record = initial),
                ).shouldBeCommitted()

            realm.commit(EditIntent.createDeleteResource(id = id)).shouldBeCommitted()
            realm.restart()

            realm.resources.keys shouldBe setOf(kept)
        }
    }

    test("a link disconnected after a reload can be connected and disconnected again") {
        RealmFixture.surreal(nodeCatalog(pairRelation())).use { realm ->
            realm
                .commit(
                    EditIntent.createCreateResource(id = source, record = node()),
                    EditIntent.createCreateResource(id = target, record = node()),
                ).shouldBeCommitted()

            repeat(2) {
                realm.commit(pair()).shouldBeCommitted()
                realm.restart()
                realm.resources.getValue(target).linkOrNull("second") shouldBe LinkTarget(resource = source, opposite = path("first"))

                realm.commit(unpair()).shouldBeCommitted()
                realm.restart()
                realm.resources.shouldHoldNoPairLink(source, target)
            }
        }
    }

    test("deleting a linked resource frees its link so a resource created under its id can be linked and unlinked after a reload") {
        RealmFixture.surreal(nodeCatalog(pairRelation())).use { realm ->
            realm
                .commit(
                    EditIntent.createCreateResource(id = source, record = node()),
                    EditIntent.createCreateResource(id = target, record = node()),
                ).shouldBeCommitted()
            realm.commit(pair()).shouldBeCommitted()
            realm.restart()

            realm.commit(EditIntent.createDeleteResource(id = target)).shouldBeCommitted()
            realm.restart()
            realm.resources
                .getValue(source)
                .linkOrNull("first")
                .shouldBeNull()

            realm.commit(EditIntent.createCreateResource(id = target, record = node())).shouldBeCommitted()
            realm.commit(pair()).shouldBeCommitted()
            realm.restart()
            realm.commit(unpair()).shouldBeCommitted()
            realm.restart()
            realm.resources
                .getValue(target)
                .linkOrNull("second")
                .shouldBeNull()
        }
    }

    test("authored records keep big integers, null, unfilled, exact decimals, bytes and item ids through a Surreal save and reload") {
        realmDatabase("edge_values").use { database ->
            val storage = SurrealAuthoringStorage(database)
            val edges =
                AuthoringRecord.of(
                    TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                    mapOf(
                        "empty" to DataValue.UNFILLED,
                        "nullable" to DataValue.NULL,
                        "integer" to DataValue.integer(BigInteger("9007199254740993123456789")),
                        "decimal" to DataValue.DecimalWrapper("1.234567890123456789"),
                        "bytes" to DataValue.bytes(byteArrayOf(0, 1, 127, -128)),
                        "list" to
                            DataValue.listValue(
                                listOf(ListItem(id = ItemId(value = "stable"), value = DataValue.StringValueWrapper("Quest"))),
                            ),
                        "map" to
                            DataValue.mapValue(
                                listOf(
                                    MapRow(
                                        id = ItemId(value = "row"),
                                        key = DataValue.StringValueWrapper("key"),
                                        value = DataValue.record(mapOf("nested" to DataValue.NULL)),
                                    ),
                                ),
                            ),
                    ),
                )

            storage.persistAtomic(AuthoringMutationPlan(mapOf(id to edges), emptySet(), NO_RELATION_CHANGES))

            storage.readCoherent().resources shouldBe mapOf(id to edges)
        }
    }

    test("a committed record is stored as a native object with its search text and a fresh owner reads it back") {
        realmDatabase("native_owner").use { database ->
            val storage = SurrealAuthoringStorage(database)
            storage.persistAtomic(AuthoringMutationPlan(mapOf(id to initial), emptySet(), NO_RELATION_CHANGES))
            val generation = CatalogGeneration(value = "fresh")
            InMemoryAuthoringViewStore(catalog.lease(generation), storage.readCoherent()).use { views ->
                RealmAuthoringOwner(storage, views).commit(rename(generation)).shouldBeCommitted()
            }

            database.query("SELECT VALUE content FROM ONLY resource:quest;").take(0).isObject shouldBe true
            database.query("SELECT VALUE search.text FROM ONLY resource:quest;").take(0).getString() shouldContain "Story"
            storage
                .readCoherent()
                .resources
                .getValue(id)
                .text("name") shouldBe "Story"
        }
    }
}

private val source = ResourceId(value = "source")
private val target = ResourceId(value = "target")

private fun pair() =
    connect(
        PAIR_FIRST,
        at(source, "first"),
        target,
        CounterpartChoice.ExistingWrapper(occurrence(PAIR_SECOND, at(target, "second"), source)),
    )

private fun unpair() = EditIntent.DisconnectRelationWrapper(LinkOccurrenceId(endpoint = PAIR_FIRST, location = at(source, "first")))

private val NO_RELATION_CHANGES = RelationProjectionDelta(removals = emptyList(), created = emptyList(), metadataChanged = emptyList())

/** An embedded SurrealDB named [name] with the Realm schema loaded. */
private fun realmDatabase(name: String) =
    Surreal().apply {
        openTestDatabase(name)
        MigrationResources().loadRealmSchema().forEach { query(it.script).take(0) }
    }
