package com.typewritermc.realm.publication

import com.surrealdb.Surreal
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import com.typewritermc.loader.api.artifact.PublicationBlobRetention
import com.typewritermc.loader.api.artifact.PublicationBlobRoots
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.storage.MigrationResources
import com.typewritermc.realm.storage.openTestDatabase
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationReport
import skirout.editor.v1.publication.PublishedRoot
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.PublicationId
import skirout.kernel.v1.resource_id.ResourceId

/** The compilation root of [projection] for [resource], as a test producer names it. */
internal fun compilationRoot(
    projection: String,
    resource: String = "root",
): CompilationRoot = CompilationRoot(projection = CompilationProjectionId(value = projection), resource = ResourceId(value = resource))

/** A fresh embedded database with the Realm schema, so publication storage starts empty and never shares state. */
internal fun publicationDatabase(): Surreal =
    Surreal().apply {
        openTestDatabase("publication_test")
        MigrationResources().loadRealmSchema().forEach { query(it.script).take(0) }
    }

/** The engine implementation inputs a test publication is compiled and activated with. */
internal fun testEngineInputs() = EngineImplementationInputs(token = InputToken(value = "implementation"))

/** A compiled artifact for [root]; each digest is its character repeated to a full SHA-256 digest. */
internal fun compiledArtifact(
    root: CompilationRoot = compilationRoot("fixture"),
    mediaType: String = "application/fixture",
    formatRevision: Int = 2,
    inputFingerprint: Char = '1',
    semanticDigest: Char = '2',
    payload: ByteArray = byteArrayOf(1),
): CompiledArtifact =
    CompiledArtifact(
        root = root,
        formatRevision = formatRevision,
        mediaType = mediaType,
        inputFingerprint = ContentDigest(inputFingerprint.toString().repeat(64)),
        semanticDigest = ContentDigest(semanticDigest.toString().repeat(64)),
        payload = payload,
    )

/**
 * A completed publication [publication] of [artifacts] on the `catalog` generation, built with [testEngineInputs], as
 * a repository returns it after installation. Every output points at the same one byte blob.
 */
internal fun publishedContent(
    artifacts: List<CompiledArtifact>,
    publication: String = "selected",
): PublishedContent =
    PublishedContent(
        publication = PublicationId(value = publication),
        formatRevision = PUBLISHED_CONTENT_FORMAT_REVISION,
        catalog = CatalogGeneration(value = "catalog"),
        implementationToken = testEngineInputs().token.value,
        outputs =
            artifacts.map { artifact ->
                PublishedOutput(
                    reference =
                        CompiledArtifactReference(
                            root = artifact.root,
                            formatRevision = artifact.formatRevision,
                            mediaType = artifact.mediaType,
                            semanticDigest = artifact.semanticDigest.value,
                        ),
                    blob = CompiledBlobPointer(digest = ContentDigest("b".repeat(64)).value, size = 1),
                )
            },
    )

/** The record a publication page fixture published for [root], titled after its resource. */
internal fun publishedPage(root: CompilationRoot): AuthoringRecord = publicationPageRecord(root.resource.value)

/** Each output root of this content with the [publishedPage] record it was compiled from. */
internal fun PublishedContent.publishedPages(): List<PublishedRoot> =
    outputs.map { PublishedRoot(root = it.reference.root, record = publishedPage(it.reference.root)) }

/** A publication source that always selects [content] and reports no attempt, as a repository holds it after a release. */
internal fun selectedPublication(content: PublishedContent): PublicationResults =
    object : PublicationResults {
        override suspend fun selected() = content

        override suspend fun latestReport(): PublicationReport? = null
    }

/**
 * A producer of [projection] in [mediaType] that offers [roots] in every view and answers each compilation with
 * [compile].
 */
internal fun compiledArtifactProducer(
    projection: String,
    mediaType: String = "application/fixture",
    roots: Set<CompilationRoot> = setOf(compilationRoot(projection)),
    compile: (Set<CompilationRoot>) -> List<CompilationResult> = { emptyList() },
): CompiledArtifactProducer =
    object : CompiledArtifactProducer {
        override val projection = CompilationProjectionId(value = projection)
        override val mediaType = mediaType

        override fun roots(view: AuthoringView): Set<CompilationRoot> = roots

        context(inputs: CompilationInputs)
        override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> = compile.invoke(roots)
    }

/** Registers [producers] and compiles an empty saved view with them, so registration and output rules both apply. */
internal fun compileEmptyView(vararg producers: CompiledArtifactProducer): List<CompilationResult> =
    InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(emptyMap())).use { views ->
        views.capture().use { capture ->
            with(CompilationInputs(capture.root, emptyMap())) { CompiledArtifactProducerRegistry(producers.toList()).compile() }
        }
    }

/**
 * Blob retention that records which digests each publication protects and which publication is selected, and refuses
 * to protect a publication twice with different digests or to select one it never protected.
 */
internal class TestPublicationRetention : PublicationBlobRetention {
    val publications = mutableMapOf<String, Set<ArtifactDigest>>()
    var selected: String? = null

    override suspend fun protect(
        publication: String,
        digests: Set<ArtifactDigest>,
    ) {
        check(publications[publication]?.let { it == digests } != false)
        publications[publication] = digests
    }

    override suspend fun selected(publication: String) {
        check(publication in publications)
        selected = publication
    }

    override suspend fun reconcile(selected: PublicationBlobRoots?) {
        publications.clear()
        this.selected = selected?.publication
        selected?.let { publications[it.publication] = it.digests }
    }
}
