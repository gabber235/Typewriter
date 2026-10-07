package com.typewritermc.realm.compiler

import com.surrealdb.Surreal
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.InputToken
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.PublishedOutput
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.schema.MigrationResources
import com.typewritermc.realm.schema.openTestDatabase
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val RegisteredCompiledContentRepositoryTest by testSuite {
    test("selection replaces the complete set and empty results remove every previous root") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val first = testPublishedContent("first", "a")
            attempts.start(first.publication, first.catalog, testEngineInputs())
            attempts.phase(first.publication, PublicationState.Activating)
            attempts.install(first)
            results.selected() shouldBe first
            val second = testPublishedContent("second", "b")
            attempts.start(second.publication, second.catalog, testEngineInputs())
            attempts.phase(second.publication, PublicationState.Activating)
            attempts.install(second)
            results.selected() shouldBe second
            results
                .states(
                    setOf(
                        first.outputs
                            .single()
                            .reference.root,
                    ),
                ).values
                .single() shouldBe RegisteredCompiledState.NotCompiled
            val empty = second.copy(publication = PublicationId("empty"), outputs = emptyList())
            attempts.start(empty.publication, empty.catalog, testEngineInputs())
            attempts.phase(empty.publication, PublicationState.Activating)
            attempts.install(empty)
            results.selected() shouldBe empty
            database
                .query("SELECT id FROM publication_attempt WHERE selected = true;")
                .take(0)
                .getArray()
                .len() shouldBe 1
        }
    }
    test("a failed installation rolls back clearing the previous selection") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val first = testPublishedContent("first", "a")
            attempts.start(first.publication, first.catalog, testEngineInputs())
            attempts.phase(first.publication, PublicationState.Activating)
            attempts.install(first)
            val next = testPublishedContent("next", "b")
            attempts.start(next.publication, next.catalog, testEngineInputs())
            shouldThrow<IllegalStateException> { attempts.install(next) }
            results.selected() shouldBe first
        }
    }
    test("blocked findings remain structured and preserve the selected result") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val finding =
                Diagnostic(
                    DiagnosticId("broken"),
                    RuleOrigin(TEST_TYPE, 0),
                    "broken",
                    "A nested value is missing",
                    DiagnosticSeverity.Error,
                    null,
                    emptyList(),
                )
            val id = PublicationId("blocked")
            attempts.start(id, CatalogGeneration("catalog"), testEngineInputs())
            attempts.blocked(id, listOf(finding))
            results.latestReport()?.findings shouldBe listOf(finding)
            database
                .query("SELECT VALUE findings FROM ONLY publication_attempt:blocked;")
                .take(0)
                .getArray()
                .single()
                .isObject shouldBe
                true
            results.selected() shouldBe null
        }
    }
    test("restart interrupts unfinished attempts without changing a completed selected attempt") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val first = testPublishedContent("first", "a")
            attempts.start(first.publication, first.catalog, testEngineInputs())
            attempts.phase(first.publication, PublicationState.Activating)
            attempts.install(first)
            attempts.start(PublicationId("unfinished"), first.catalog, testEngineInputs())
            SurrealPublicationAttemptStore(database).interruptUnfinished()
            results.selected() shouldBe first
            database.query("SELECT VALUE state FROM ONLY publication_attempt:unfinished;").take(0).getString() shouldBe "interrupted"
            database.query("SELECT VALUE state FROM ONLY publication_attempt:first;").take(0).getString() shouldBe "complete"
        }
    }
}

internal fun publicationDatabase(): Surreal =
    Surreal().apply {
        openTestDatabase("publication_test")
        MigrationResources().loadRealmSchema().forEach { query(it.script).take(0) }
    }

internal fun testEngineInputs() = EngineImplementationInputs(emptySet(), InputToken("implementation"))

internal fun testPublishedContent(
    id: String,
    resource: String,
): PublishedContent =
    PublishedContent(
        PublicationId(id),
        2,
        CatalogGeneration("catalog"),
        "implementation",
        emptySet(),
        listOf(
            PublishedOutput(
                CompiledArtifactReference(
                    CompilationRoot(CompilationProjectionId("test"), ResourceId(resource)),
                    1,
                    "application/test",
                    ContentDigest("a".repeat(64)),
                ),
                CompiledBlobPointer(ContentDigest("b".repeat(64)), 1),
            ),
        ),
    )
