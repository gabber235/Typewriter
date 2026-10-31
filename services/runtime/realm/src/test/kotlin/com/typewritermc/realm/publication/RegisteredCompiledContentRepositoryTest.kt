package com.typewritermc.realm.publication

import com.typewritermc.realm.authoring.TEST_TYPE
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.publication.PublicationReport
import skirout.editor.v1.publication.PublicationState
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.RuleOrigin

val RegisteredCompiledContentRepositoryTest by testSuite {
    test("each installation becomes the only selected publication, an empty one included") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val first = publishedContent(listOf(compiledArtifact(compilationRoot("test", "a"))), publication = "first")
            attempts.start(first.publication, first.catalog, testEngineInputs())
            attempts.phase(first.publication, PublicationState.ACTIVATING)
            attempts.install(first, first.publishedPages())
            results.selected() shouldBe first
            val second = publishedContent(listOf(compiledArtifact(compilationRoot("test", "b"))), publication = "second")
            attempts.start(second.publication, second.catalog, testEngineInputs())
            attempts.phase(second.publication, PublicationState.ACTIVATING)
            attempts.install(second, second.publishedPages())
            results.selected() shouldBe second
            val empty = second.copy(publication = PublicationId(value = "empty"), outputs = emptyList())
            attempts.start(empty.publication, empty.catalog, testEngineInputs())
            attempts.phase(empty.publication, PublicationState.ACTIVATING)
            attempts.install(empty, empty.publishedPages())
            results.selected() shouldBe empty
        }
    }
    test("installing an attempt that never reached activation is refused and keeps the previous selection") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val first = publishedContent(listOf(compiledArtifact(compilationRoot("test", "a"))), publication = "first")
            attempts.start(first.publication, first.catalog, testEngineInputs())
            attempts.phase(first.publication, PublicationState.ACTIVATING)
            attempts.install(first, first.publishedPages())
            val next = publishedContent(listOf(compiledArtifact(compilationRoot("test", "b"))), publication = "next")
            attempts.start(next.publication, next.catalog, testEngineInputs())
            shouldThrow<IllegalStateException> { attempts.install(next, next.publishedPages()) }.message shouldBe
                "Publication was not ready for installation"
            results.selected() shouldBe first
        }
    }
    test("recovery fences an unfinished installation and preserves the prior selection") {
        publicationDatabase().use { database ->
            val original = SurrealPublicationAttemptStore(database)
            val recovery = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val selected = publishedContent(listOf(compiledArtifact(compilationRoot("test", "first"))), publication = "selected")
            original.start(selected.publication, selected.catalog, testEngineInputs())
            original.phase(selected.publication, PublicationState.ACTIVATING)
            original.install(selected, selected.publishedPages())
            val unfinished = publishedContent(listOf(compiledArtifact(compilationRoot("test", "second"))), publication = "unfinished")
            original.start(unfinished.publication, unfinished.catalog, testEngineInputs())
            original.phase(unfinished.publication, PublicationState.ACTIVATING)
            recovery.interruptUnfinished()
            shouldThrow<IllegalStateException> { original.install(unfinished, unfinished.publishedPages()) }.message shouldBe
                "Publication was not ready for installation"
            results.selected() shouldBe selected
            results.latestReport()?.state shouldBe PublicationState.INTERRUPTED
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
            results.latestReport() shouldBe
                PublicationReport(id = id, state = PublicationState.BlockedWrapper(listOf(finding)), findings = listOf(finding))
            results.selected() shouldBe null
        }
    }
    test("restart interrupts unfinished attempts without changing a completed selected attempt") {
        publicationDatabase().use { database ->
            val attempts = SurrealPublicationAttemptStore(database)
            val results = SurrealRegisteredCompiledContentRepository(database)
            val first = publishedContent(listOf(compiledArtifact(compilationRoot("test", "a"))), publication = "first")
            attempts.start(first.publication, first.catalog, testEngineInputs())
            attempts.phase(first.publication, PublicationState.ACTIVATING)
            attempts.install(first, first.publishedPages())
            attempts.start(PublicationId(value = "unfinished"), first.catalog, testEngineInputs())
            SurrealPublicationAttemptStore(database).interruptUnfinished()
            results.selected() shouldBe first
            results.latestReport() shouldBe
                PublicationReport(id = PublicationId(value = "unfinished"), state = PublicationState.INTERRUPTED, findings = emptyList())
        }
    }
}
