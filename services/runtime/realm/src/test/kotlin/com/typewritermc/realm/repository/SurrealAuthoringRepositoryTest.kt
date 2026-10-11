package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.authoredDatabaseValues
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.location
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.schema.MigrationResources
import com.typewritermc.realm.schema.openTestDatabase
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe

val SurrealAuthoringRepositoryTestSuite by testSuite {
    val id = ResourceId("quest")
    val initial = record(name = "Quest", count = 1)
    val title = location(id, "name")

    fun edit(
        catalog: CatalogGeneration,
        expected: String = "Quest",
        next: String = "Story",
    ) = PreparedEdit(
        catalog,
        listOf(
            EditExpectation.ResourceExists(id, true),
            EditExpectation.Configuration(ValueLocation(id, ValuePath()), initial.configuration),
            EditExpectation.Configuration(title, null),
            EditExpectation.Value(title, DataValue.StringValue(expected)),
        ),
        listOf(EditIntent.SetValue(title, DataValue.StringValue(next))),
    )

    test("independent fields remain compatible and a changed expected title conflicts") {
        val catalog = TestCatalogLease()
        val seed =
            AuthoringSeed(
                mapOf(id to initial.copy(fields = initial.fields + ("count" to DataValue.Integer(java.math.BigInteger.TWO)))),
            )
        val storage = MemoryAuthoringStorage(seed)
        val views = InMemoryAuthoringViewStore(catalog, seed)
        val owner = RealmAuthoringOwner(storage, views)
        owner.commit(edit(catalog.generation)) shouldBe CommitResult.Committed
        views.capture().use {
            it.root.resources
                .getValue(id)
                .fields["count"] shouldBe DataValue.Integer(java.math.BigInteger.TWO)
        }
        val conflict = owner.commit(edit(catalog.generation)) as CommitResult.Conflict
        conflict.values shouldHaveSize 1
        storage.writes shouldBe 1
        owner.commit(edit(catalog.generation, "Story", "Quest")) shouldBe CommitResult.Committed
        owner.commit(edit(catalog.generation)) shouldBe CommitResult.Committed
        views.close()
    }
    test("an unguarded write is rejected and never persisted") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        val owner = RealmAuthoringOwner(storage, views)
        val result = owner.commit(edit(catalog.generation).copy(expectations = emptyList())) as CommitResult.Rejected
        result.problems.any { it.code == "missing_expectation" } shouldBe true
        storage.writes shouldBe 0
        views.close()
    }
    test("catalog changes reject old requests before storage") {
        val catalog = TestCatalogLease()
        val storage = MemoryAuthoringStorage(AuthoringSeed(mapOf(id to initial)))
        val views = InMemoryAuthoringViewStore(catalog, storage.seed)
        val owner = RealmAuthoringOwner(storage, views)
        val replacement = TestCatalogLease(generation = CatalogGeneration("replacement"))
        var installed = false
        var published = false
        owner.activateCatalog(replacement, { installed = true }, { published = true })
        installed shouldBe true
        published shouldBe true
        owner.commit(edit(catalog.generation)) shouldBe CommitResult.CatalogChanged(replacement.generation)
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
                .fields["name"] shouldBe DataValue.StringValue("Story")
        }
        (owner.commit(edit(catalog.generation)) is CommitResult.Conflict) shouldBe true
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
        owner.commit(edit(catalog.generation)) shouldBe CommitResult.Committed
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
                    com.typewritermc.authoring.RelationProjectionDelta(emptyList(), emptyList(), emptyList()),
                    mapOf(id to ResourceDefinitionId("test")),
                ),
            )
            val catalog = TestCatalogLease()
            val views = InMemoryAuthoringViewStore(catalog, storage.readCoherent())
            RealmAuthoringOwner(storage, views).commit(edit(catalog.generation)) shouldBe CommitResult.Committed
            val content = database.query("SELECT VALUE content FROM ONLY resource:quest;").take(0)
            content.isObject shouldBe true
            authoredDatabaseValues.decode(AuthoringRecord.serializer(), content).fields["name"] shouldBe DataValue.StringValue("Story")
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
                    .fields["name"] shouldBe DataValue.StringValue("Story")
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
            AuthoringSeed(
                seed.resources + plan.resources - plan.removedResources,
                seed.resourceDefinitions + plan.definitions - plan.removedResources,
            )
        check(!failAfterWrite) { "commit result unavailable" }
    }
}
