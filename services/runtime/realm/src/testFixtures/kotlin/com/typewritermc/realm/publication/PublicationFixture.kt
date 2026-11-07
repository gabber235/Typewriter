package com.typewritermc.realm.publication

import com.typewritermc.authoring.CompilationUnitDefinition
import com.typewritermc.authoring.of
import com.typewritermc.engine.decodeResourceGraphShard
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.recordBinding
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.types.field
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.publication.PublicationState
import skirout.editor.v1.publication.PublicationStatus
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * A publication coordinator over saved views of the publication page catalog, assessed by production acceptance and
 * recorded in an embedded SurrealDB with the Realm schema. Hooks inject failures and pauses at the seams a test needs.
 */
internal class PublicationFixture(
    initial: Map<ResourceId, AuthoringRecord> = mapOf(PUBLICATION_PAGE_ID to publicationPageRecord("Quest")),
    producers: List<CompiledArtifactProducer> = listOf(ResourceGraphArtifactProducer),
) {
    val views = InMemoryAuthoringViewStore(PUBLICATION_CATALOG.lease(), AuthoringSeed(initial))
    private val checks = RealmCheckRuntime(views)
    private val database = publicationDatabase()
    val attempts = SurrealPublicationAttemptStore(database)
    val results = SurrealRegisteredCompiledContentRepository(database)
    val retention = TestPublicationRetention()
    val root = CompilationRoot(projection = CompilationProjectionId(value = "typewriter.resource-graph"), resource = PUBLICATION_PAGE_ID)
    var engineInputs = testEngineInputs()
    var blobRequests = 0
    var captureFailure = false
    var findings = emptyList<FindingSet>()

    /** Runs while saved content is assessed. */
    var onEvaluate: (suspend () -> Unit)? = null

    /** Runs before each compiled blob is stored, while an attempt is storing its artifacts. */
    var onStore: suspend () -> Unit = {}
    val blobs = InMemoryBlobEndpoint()
    private val acceptance = AuthoringAcceptance(views, checks)
    val publisher =
        RealmPublicationCoordinator(
            object : PublicationAcceptance {
                override fun capture(): AuthoringLease {
                    check(!captureFailure) { "Saved content is unavailable" }
                    return acceptance.capture()
                }

                override fun <T> withCurrent(block: (AuthoringView) -> T): T = acceptance.withCurrent(block)

                override suspend fun evaluate(capture: AuthoringLease): CapturedAssessment {
                    onEvaluate?.invoke()
                    return acceptance.evaluate(capture)
                }
            },
            attempts,
            RegisteredCompiledArtifactStore(
                object : BlobEndpoint by blobs {
                    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> {
                        blobRequests++
                        return blobs.metadata(digest)
                    }

                    override suspend fun store(
                        expected: BlobMetadata,
                        content: ByteArray,
                    ): StoreResult {
                        onStore()
                        return blobs.store(expected, content)
                    }
                },
                retention,
            ),
            object : EngineImplementationSource {
                override fun capture() = engineInputs
            },
            CompiledArtifactProducerRegistry(producers),
            results,
            findings = { findings },
        )

    /** The ready status the last refresh produced; fails when publication is in any other state. */
    fun ready() =
        publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.ReadyWrapper>()
            .value

    /** Saves the page with [value], as an author's committed edit would. */
    fun update(value: String) = views.install(views.prepare(AuthoringViewDelta(mapOf(PUBLICATION_PAGE_ID to publicationPageRecord(value)))))

    /** Refreshes and publishes the ready candidate; fails unless the publication activates. */
    suspend fun release(): PublicationResult.Activated {
        publisher.refresh()
        return publisher.publish(ready().candidate).shouldBeInstanceOf<PublicationResult.Activated>()
    }

    /** Selects [content] as another writer's completed publication would. */
    suspend fun installElsewhere(content: PublishedContent) {
        attempts.start(content.publication, content.catalog, testEngineInputs())
        attempts.phase(content.publication, PublicationState.ACTIVATING)
        attempts.install(content, content.publishedPages())
    }

    /** The page's authored value as the stored resource graph of [content] carries it. */
    fun publishedPageValue(content: PublishedContent): DataValue? {
        val payload =
            blobs.content(
                ArtifactDigest(
                    DigestAlgorithm.SHA_256,
                    content.outputs
                        .single()
                        .blob.digest,
                ),
            )
        val page =
            payload
                .decodeResourceGraphShard()
                .facts.resources
                .single { it.key.source == PUBLICATION_PAGE_ID }
        return (page.value.payload as DataValue.RecordWrapper).field("value")
    }

    /** A finding set of the page check numbered [rule], witnessed by [expectations] on the current catalog. */
    fun findingSet(
        rule: Int,
        expectations: List<EditExpectation>,
        status: FindingStatus,
    ): FindingSet {
        val location = ValueLocation.of(PUBLICATION_PAGE_ID)
        return FindingSet(
            ticket =
                CheckTicket(
                    instance =
                        CheckInstanceId(
                            rule = RuleId(origin = RuleOrigin(owner = PUBLICATION_PAGE, ordinal = 0), localIndex = rule),
                            location = location,
                        ),
                    catalog = views.read { it.catalog.generation },
                ),
            expectations = expectations,
            outcome = CheckOutcome.FINISHED,
            findings = listOf(compilationDiagnostic("external_check", "An external input requires attention.", location = location)),
            status = status,
        )
    }

    /** Stops the coordinator and releases its checks, views and database. */
    suspend fun close() {
        publisher.close()
        checks.close()
        views.close()
        database.close()
    }
}

/** A complete publication page whose text value is [value]. */
internal fun publicationPageRecord(value: String) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(PUBLICATION_PAGE_USE),
        mapOf("value" to DataValue.StringValueWrapper(value)),
    )

/** The page type of the publication catalog: a compilation unit with one text value. */
internal val PUBLICATION_PAGE = TypeDefinitionId.qualified("publication", "page")
private val PUBLICATION_PAGE_USE = PUBLICATION_PAGE.namedUse()

/** The definitions of the publication catalog: the compilation unit base and [PUBLICATION_PAGE]. */
internal val PUBLICATION_DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = CompilationUnitDefinition.id,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
        ),
        TypeDefinition.partial(
            id = PUBLICATION_PAGE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = PUBLICATION_PAGE, name = "value"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    form = RecordForm.CONCRETE,
                ),
            parents = listOf(CompilationUnitDefinition.id.namedTemplate()),
        ),
    )

/** The page a [PublicationFixture] saves by default. */
internal val PUBLICATION_PAGE_ID = ResourceId(value = "page")

/** The publication catalog: [PUBLICATION_DEFINITIONS] with a native binding for the page. */
internal val PUBLICATION_CATALOG =
    DefinitionCatalog(PUBLICATION_DEFINITIONS, nativeBindingFactories = listOf(recordBinding(PUBLICATION_PAGE)))
