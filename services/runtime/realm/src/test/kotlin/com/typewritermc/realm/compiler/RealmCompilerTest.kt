package com.typewritermc.realm.compiler

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementRevision
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ReferenceDecomposer
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.ref
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledShardPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.TestPageKinds
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.realm.repository.CreateElementsCommand
import com.typewritermc.realm.repository.ElementBatchResult
import com.typewritermc.realm.repository.ElementCreation
import com.typewritermc.realm.repository.PageDocumentCatalog
import com.typewritermc.realm.repository.RepositoryFixture
import com.typewritermc.realm.repository.SurrealPageDocumentRepository
import com.typewritermc.realm.repository.createBook
import com.typewritermc.realm.repository.createPage
import com.typewritermc.realm.repository.successValue
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import kotlin.uuid.Uuid
import com.typewritermc.library.ref as pageRef

val RealmCompilerTest by testSuite {
    test("successful compiles activate and reuse persisted page shards") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.compilePage("success")
                val content = SurrealCompiledContentRepository(fixture.database)
                val compiler = RealmCompiler(content, testArtifacts)

                val first =
                    compiler.compile(snapshot = compilerSnapshot(fixture), catalogRevision = "catalog:1")
                        as RealmCompileResult.Activated
                val second =
                    compiler.compile(snapshot = compilerSnapshot(fixture), catalogRevision = "catalog:1")
                        as RealmCompileResult.Activated

                first.reusedShardCount shouldBe 0
                second.reusedShardCount shouldBe 1
                second.shards.single().digest shouldBe first.shards.single().digest
                content.activeManifest()?.digest shouldBe second.manifest.digest
            }
        }
    }

    test("blocked compiles retain the last active manifest") {
        runTest {
            RepositoryFixture().use { fixture ->
                val stablePage = fixture.compilePage("stable")
                val invalidPage = fixture.compilePage("invalid")
                val content = SurrealCompiledContentRepository(fixture.database)
                val documents = SurrealPageDocumentRepository(fixture.database) { null }
                val compiler = RealmCompiler(content, testArtifacts)
                val active = compiler.compile(compilerSnapshot(fixture), "catalog:1") as RealmCompileResult.Activated
                fixture.elements.createElements(
                    CreateElementsCommand(
                        BatchId("invalid-compile-seed"),
                        listOf(ElementCreation(invalidPage.pageRef(), danglingElement())),
                    ),
                )

                val blocked = compiler.compile(compilerSnapshot(fixture), "catalog:1") as RealmCompileResult.Blocked

                blocked.diagnostics.any { it.code == "dangling-reference" } shouldBe true
                blocked.activeManifest?.digest shouldBe active.manifest.digest
                content.activeManifest()?.digest shouldBe active.manifest.digest
            }
        }
    }

    test("authoring changes after artifact upload prevent activation") {
        runTest {
            RepositoryFixture().use { fixture ->
                val page = fixture.compilePage("stale")
                val snapshot = compilerSnapshot(fixture)
                var uploads = 0
                val artifacts =
                    CompiledArtifactPublisher { revision, manifest, shards ->
                        uploads++
                        fixture.elements
                            .createElements(
                                CreateElementsCommand(
                                    BatchId("stale-after-upload"),
                                    listOf(ElementCreation(page.pageRef(), danglingElement())),
                                ),
                            ) as ElementBatchResult.Success
                        testArtifacts.store(revision, manifest, shards)
                    }
                val content = SurrealCompiledContentRepository(fixture.database)
                val compiler = RealmCompiler(content, artifacts)

                compiler.compile(snapshot, "catalog:1") shouldBe RealmCompileResult.Stale

                uploads shouldBe 1
                content.activeManifest() shouldBe null
            }
        }
    }

    test("content addressed database rows reject conflicting payloads") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.compilePage("immutable")
                val content = SurrealCompiledContentRepository(fixture.database)
                val compiler = RealmCompiler(content, testArtifacts)
                val active = compiler.compile(compilerSnapshot(fixture), "catalog:1") as RealmCompileResult.Activated
                val conflicting = active.shards.single().copy(inputFingerprint = ContentDigest("f".repeat(64)))
                val activation = testArtifacts.store(2, active.manifest, listOf(conflicting))

                shouldThrow<IllegalStateException> {
                    content.publish(active.manifest, listOf(conflicting), activation)
                }

                content.activeManifest()?.digest shouldBe active.manifest.digest
            }
        }
    }
}

private val testArtifacts =
    CompiledArtifactPublisher { revision, manifest, shards ->
        CompiledContentActivation(
            activationRevision = revision,
            manifestDigest = manifest.digest,
            manifest = CompiledBlobPointer(manifest.digest, 0),
            shards = shards.map { CompiledShardPointer(it.digest, CompiledBlobPointer(it.digest, 0)) },
        )
    }

private suspend fun compilerSnapshot(fixture: RepositoryFixture) =
    SurrealPageDocumentRepository(fixture.database) { null }.getAuthoringSnapshot()

private suspend fun RepositoryFixture.compilePage(name: String): com.typewritermc.library.PageId {
    val book = books.createBook("${name}_compile_book", name, Color(argb = 0), emptyList()).successValue()
    return pages
        .createPage(book.bookId, "${name}_compile_page", TestPageKinds.STATIC, "", 0)
        .successValue()
        .pageId
        .toPageId()
}

private fun danglingElement(): StoredElement {
    val value =
        ReferenceDecomposer { ReferenceSlotId("missing") }.decompose(
            TypeGraph(REFERENCE_TYPE, emptyList()),
            DataValue.StringValue(MISSING_ID.ref<com.typewritermc.elements.Element>().id.referenceString()),
        )
    return StoredElement(
        id = INVALID_ID,
        revision = ElementRevision(1),
        elementType = INVALID_TYPE,
        schemaRevision = 1,
        name = "Invalid",
        value = value,
        placement = ElementPlacement.Graph(0, 0, 1, 1),
    )
}

private val INVALID_ID = ElementInstanceId(Uuid.parseHex("70000000000000000000000000000001"))
private val MISSING_ID = ElementInstanceId(Uuid.parseHex("70000000000000000000000000000002"))
private val INVALID_TYPE = ElementTypeId(DeclaredTypeId.parse("70000000000000000000000000000003"))
private val REFERENCE_TYPE =
    TypeExpression.Named(
        ResolvedTypeRef(
            TypeId.Qualified("typewriter/v1", "Ref"),
            revision = 1,
            arguments = listOf(TypeExpression.Any),
        ),
    )
