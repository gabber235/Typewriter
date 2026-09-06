package com.typewritermc.realm.compiler

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ref
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledShardPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.TestPageKinds
import com.typewritermc.realm.repository.AuthoringBatch
import com.typewritermc.realm.repository.AuthoringElement
import com.typewritermc.realm.repository.AuthoringOperation
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.realm.repository.PageDocumentCatalog
import com.typewritermc.realm.repository.RepositoryFixture
import com.typewritermc.realm.repository.SurrealPageDocumentRepository
import com.typewritermc.realm.routes.toLibrary
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
                var blockedSignals = 0
                val content =
                    SurrealCompiledContentRepository(
                        fixture.database,
                        onBlocked = { blockedSignals++ },
                    )
                val documents = SurrealPageDocumentRepository(fixture.database) { null }
                val compiler = RealmCompiler(content, testArtifacts)
                val active = compiler.compile(compilerSnapshot(fixture), "catalog:1") as RealmCompileResult.Activated
                fixture.createDanglingElement(invalidPage, "invalid-compile-seed")

                val blocked = compiler.compile(compilerSnapshot(fixture), "catalog:1") as RealmCompileResult.Blocked

                blocked.diagnostics.any { it.code == "dangling-reference" } shouldBe true
                blocked.activeManifest?.digest shouldBe active.manifest.digest
                content.activeManifest()?.digest shouldBe active.manifest.digest
                blockedSignals shouldBe 1
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
                        fixture.createDanglingElement(page, "stale-after-upload")
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
    val book = createBook("${name}_compile_book", name)
    return createPage("${name}_compile_page", book.id, TestPageKinds.STATIC.toLibrary()).id
}

private suspend fun RepositoryFixture.createDanglingElement(
    page: com.typewritermc.library.PageId,
    batchId: String,
) {
    registerElementType(INVALID_TYPE, TypeGraph(REFERENCE_TYPE, emptyList()))
    authoring.apply(
        AuthoringBatch(
            BatchId(batchId),
            listOf(
                AuthoringOperation.CreateElement(
                    AuthoringElement(
                        id = INVALID_ID,
                        page = page.pageRef(),
                        elementType = INVALID_TYPE,
                        schemaRevision = 1,
                        name = "Invalid",
                        value = DataValue.StringValue(MISSING_ID.ref<com.typewritermc.elements.Element>().id.referenceString()),
                        placement = ElementPlacement.Graph(0, 0, 1, 1),
                    ),
                ),
            ),
        ),
    )
}

private val INVALID_ID = ElementInstanceId("70000000000000000000000000000001")
private val MISSING_ID = ElementInstanceId("70000000000000000000000000000002")
private val INVALID_TYPE = ElementTypeId(DeclaredTypeId.parse("70000000000000000000000000000003"))
private val REFERENCE_TYPE =
    TypeExpression.Named(
        ResolvedTypeRef(
            TypeId.Qualified("typewriter/v1", "Ref"),
            revision = 1,
            arguments = listOf(TypeExpression.Any),
        ),
    )
