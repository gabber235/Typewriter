package com.typewritermc.realm.compiler

import com.surrealdb.Surreal
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.schema.MigrationResources
import com.typewritermc.realm.schema.openTestDatabase
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationState
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.RuleOrigin

val RegisteredCompiledContentRepositoryTest by testSuite {
    test("selection replaces the complete set and empty results remove every previous root") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val first = testPublishedContent("first", "a")
            attempts.start(first.publication, first.catalog, testEngineInputs())
            attempts.phase(first.publication, PublicationState.ACTIVATING)
            attempts.install(first)
            results.selected() shouldBe first
            val second = testPublishedContent("second", "b")
            attempts.start(second.publication, second.catalog, testEngineInputs())
            attempts.phase(second.publication, PublicationState.ACTIVATING)
            attempts.install(second)
            results.selected() shouldBe second
            val empty = second.copy(publication = PublicationId(value = "empty"), outputs = emptyList())
            attempts.start(empty.publication, empty.catalog, testEngineInputs())
            attempts.phase(empty.publication, PublicationState.ACTIVATING)
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
            attempts.phase(first.publication, PublicationState.ACTIVATING)
            attempts.install(first)
            val next = testPublishedContent("next", "b")
            attempts.start(next.publication, next.catalog, testEngineInputs())
            shouldThrow<IllegalStateException> { attempts.install(next) }
            results.selected() shouldBe first
        }
    }
    test("recovery fences an unfinished installation and preserves the prior selection") {
        publicationDatabase().use { database ->
            val original = SurrealPublicationAttemptStore(database)
            val recovery = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val selected = testPublishedContent("selected", "first")
            original.start(selected.publication, selected.catalog, testEngineInputs())
            original.phase(selected.publication, PublicationState.ACTIVATING)
            original.install(selected)
            val unfinished = testPublishedContent("unfinished", "second")
            original.start(unfinished.publication, unfinished.catalog, testEngineInputs())
            original.phase(unfinished.publication, PublicationState.ACTIVATING)
            recovery.interruptUnfinished()
            shouldThrow<IllegalStateException> { original.install(unfinished) }
            results.selected() shouldBe selected
        }
    }
    test("blocked findings remain structured and preserve the selected result") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val finding =
                Diagnostic(
                    id = DiagnosticId(value = "broken"),
                    origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0),
                    code = "broken",
                    message = "A nested value is missing",
                    severity = DiagnosticSeverity.ERROR,
                    primary = null,
                    related = emptyList(),
                )
            val id = PublicationId(value = "blocked")
            attempts.start(id, CatalogGeneration(value = "catalog"), testEngineInputs())
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
            attempts.phase(first.publication, PublicationState.ACTIVATING)
            attempts.install(first)
            attempts.start(PublicationId(value = "unfinished"), first.catalog, testEngineInputs())
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

internal fun testEngineInputs() =
    EngineImplementationInputs(
        token =
            skirout.editor.v1.type_catalog
                .InputToken(value = "implementation"),
    )

internal fun testPublishedContent(
    id: String,
    resource: String,
): PublishedContent =
    PublishedContent(
        publication = PublicationId(value = id),
        formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
        catalog = CatalogGeneration(value = "catalog"),
        implementationToken = "implementation",
        outputs =
            listOf(
                PublishedOutput(
                    reference =
                        CompiledArtifactReference(
                            root =
                                CompilationRoot(
                                    projection = CompilationProjectionId(value = "test"),
                                    resource = ResourceId(value = resource),
                                ),
                            formatRevision = 1,
                            mediaType = "application/test",
                            semanticDigest = ContentDigest("a".repeat(64)).value,
                        ),
                    blob = CompiledBlobPointer(digest = ContentDigest("b".repeat(64)).value, size = 1),
                ),
            ),
    )
