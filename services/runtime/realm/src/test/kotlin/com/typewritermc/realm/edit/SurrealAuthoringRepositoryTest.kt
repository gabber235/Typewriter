package com.typewritermc.realm.edit

import com.surrealdb.Surreal
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.publication.AuthoringAcceptance
import com.typewritermc.realm.storage.MigrationResources
import com.typewritermc.realm.storage.decodeSkir
import com.typewritermc.realm.storage.openTestDatabase
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val SurrealAuthoringRepositoryTestSuite by testSuite {
    val id = ResourceId(value = "quest")
    val initial = record(name = "Quest", count = 1)
    val title = location(id, "name")

    fun edit(
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

    test("independent fields remain compatible and a changed expected title conflicts") {
        val catalog = TestCatalogLease()
        val seed =
            AuthoringSeed(
                mapOf(id to initial.with("count", DataValue.integer(java.math.BigInteger.TWO))),
            )
        val storage = MemoryAuthoringStorage(seed)
        val views = InMemoryAuthoringViewStore(catalog, seed)
        val owner = RealmAuthoringOwner(storage, views)
        owner.commit(edit(catalog.generation)) shouldBe CommitPreparedEditResponse.COMMITTED
        views.capture().use {
            it.root.resources
                .getValue(id)
                .field("count") shouldBe DataValue.integer(java.math.BigInteger.TWO)
        }
        val conflict = owner.commit(edit(catalog.generation)) as CommitPreparedEditResponse.ConflictErrorWrapper
        conflict.value shouldHaveSize 1
        storage.writes shouldBe 1
        owner.commit(edit(catalog.generation, "Story", "Quest")) shouldBe CommitPreparedEditResponse.COMMITTED
        owner.commit(edit(catalog.generation)) shouldBe CommitPreparedEditResponse.COMMITTED
        views.close()
    }
    test("ordered field edits use one original saved expectation") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        try {
            val request =
                edit(catalog.generation).copy(
                    intents =
                        listOf("Q", "Qu", "Story").map {
                            EditIntent.createSetValue(at = title, value = DataValue.StringValueWrapper(it))
                        },
                )
            RealmAuthoringOwner(storage, views).commit(request) shouldBe CommitPreparedEditResponse.COMMITTED
            storage.writes shouldBe 1
            views.capture().use { saved ->
                saved.root.resources
                    .getValue(id)
                    .field("name") shouldBe DataValue.StringValueWrapper("Story")
            }
        } finally {
            views.close()
        }
    }

    test("an intermediate local expectation conflicts without a write") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        try {
            val request =
                edit(catalog.generation, expected = "Qu").copy(
                    intents =
                        listOf("Q", "Qu", "Story").map {
                            EditIntent.createSetValue(at = title, value = DataValue.StringValueWrapper(it))
                        },
                )
            val result = RealmAuthoringOwner(storage, views).commit(request) as CommitPreparedEditResponse.ConflictErrorWrapper
            result.value shouldHaveSize 1
            result.value.single().actual shouldBe EditExpectation.createValue(at = title, expected = DataValue.StringValueWrapper("Quest"))
            storage.writes shouldBe 0
        } finally {
            views.close()
        }
    }

    test("unfinished authoring content persists but publication rejects it") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        val checks = RealmCheckRuntime(views)
        try {
            val request = edit(catalog.generation).copy(intents = listOf(EditIntent.createSetValue(at = title, value = DataValue.UNFILLED)))
            RealmAuthoringOwner(storage, views).commit(request) shouldBe CommitPreparedEditResponse.COMMITTED
            storage.writes shouldBe 1
            storage
                .readCoherent()
                .resources
                .getValue(id)
                .field("name") shouldBe DataValue.UNFILLED
            views.capture().use { saved ->
                saved.root.resources
                    .getValue(id)
                    .field("name") shouldBe DataValue.UNFILLED
                val blocked = AuthoringAcceptance(views, checks).evaluate(saved)
                blocked.findings.any { it.code == "unfinished_value" && it.primary == title } shouldBe true
            }
        } finally {
            checks.close()
            views.close()
        }
    }
    test("an unguarded write is rejected and never persisted") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        val owner = RealmAuthoringOwner(storage, views)
        val result =
            owner.commit(
                edit(catalog.generation).copy(expectations = emptyList()),
            ) as CommitPreparedEditResponse.RejectedErrorWrapper
        result.value.any { it.code == "missing_expectation" } shouldBe true
        storage.writes shouldBe 0
        views.close()
    }
    test("catalog changes reject old requests before storage") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        val owner = RealmAuthoringOwner(storage, views)
        val replacement = TestCatalogLease(generation = CatalogGeneration(value = "replacement"))
        var installed = false
        var published = false
        owner.activateCatalog(replacement, { installed = true }, { published = true })
        installed shouldBe true
        published shouldBe true
        owner.commit(edit(catalog.generation)) shouldBe CommitPreparedEditResponse.CatalogChangedErrorWrapper(replacement.generation)
        storage.writes shouldBe 0
        replacement.close()
        views.close()
    }
    test("uncertain persistence reloads committed state and keeps the original lease") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        val retained = views.capture()
        val owner = RealmAuthoringOwner(storage, views)
        storage.failAfterWrite = true
        shouldThrow<IllegalStateException> { owner.commit(edit(catalog.generation)) }
        storage.failReads = true
        shouldThrow<IllegalStateException> { views.capture() }
        retained.root.resources[id] shouldBe initial
        storage.failReads = false
        views.capture().use {
            it.root.resources
                .getValue(id)
                .field("name") shouldBe DataValue.StringValueWrapper("Story")
        }
        (owner.commit(edit(catalog.generation)) is CommitPreparedEditResponse.ConflictErrorWrapper) shouldBe true
        storage.writes shouldBe 1
        retained.close()
        views.close()
    }
    test("a failed write reloads the unchanged database before accepting another edit") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        val owner = RealmAuthoringOwner(storage, views)
        storage.failBeforeWrite = true
        shouldThrow<IllegalStateException> { owner.commit(edit(catalog.generation)) }
        storage.failBeforeWrite = false
        owner.commit(edit(catalog.generation)) shouldBe CommitPreparedEditResponse.COMMITTED
        storage.reads shouldBe 1
        views.close()
    }
    test("native objects and search fields survive a fresh owner reading the database") {
        Surreal().use { database ->
            database.openTestDatabase("native_owner")
            MigrationResources().loadRealmSchema().forEach { database.query(it.script).take(0) }
            val storage = SurrealAuthoringStorage(database)
            storage.persistAtomic(
                AuthoringMutationPlan(
                    mapOf(id to initial),
                    emptySet(),
                    skirout.editor.v1.authoring.RelationProjectionDelta(
                        removals = emptyList(),
                        created = emptyList(),
                        metadataChanged = emptyList(),
                    ),
                ),
            )
            val catalog = TestCatalogLease()
            val views = InMemoryAuthoringViewStore(catalog, storage.readCoherent())
            RealmAuthoringOwner(storage, views).commit(edit(catalog.generation)) shouldBe CommitPreparedEditResponse.COMMITTED
            val content = database.query("SELECT VALUE content FROM ONLY resource:quest;").take(0)
            content.isObject shouldBe true
            decodeSkir(AuthoringRecord.serializer, content).field("name") shouldBe
                DataValue.StringValueWrapper("Story")
            database
                .query("SELECT VALUE search.text FROM ONLY resource:quest;")
                .take(0)
                .getString()
                .contains("Story") shouldBe true
            views.close()
            val restarted = InMemoryAuthoringViewStore(TestCatalogLease(), storage.readCoherent())
            restarted.capture().use {
                it.root.resources
                    .getValue(id)
                    .field("name") shouldBe DataValue.StringValueWrapper("Story")
            }
            restarted.close()
        }
    }
}

private class MemoryAuthoringStorage(
    var seed: AuthoringSeed,
) : AuthoringStorage {
    var writes = 0
    var reads = 0
    var failBeforeWrite = false
    var failAfterWrite = false
    var failReads = false

    override fun readCoherent(): AuthoringSeed {
        reads++
        check(!failReads) { "read unavailable" }
        return seed
    }

    override fun persistAtomic(plan: AuthoringMutationPlan) {
        check(!failBeforeWrite) { "write unavailable" }
        writes++
        seed =
            AuthoringSeed(seed.resources + plan.resources - plan.removedResources)
        check(!failAfterWrite) { "commit result unavailable" }
    }
}
