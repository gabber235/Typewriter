package com.typewritermc.realm.publication

import com.typewritermc.authoring.CompilationUnitDefinition
import com.typewritermc.authoring.of
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.ContentDigest
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
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationBaseline
import skirout.editor.v1.publication.PublicationCandidateId
import skirout.editor.v1.publication.PublicationChange
import skirout.editor.v1.publication.PublicationFailure
import skirout.editor.v1.publication.PublicationReport
import skirout.editor.v1.publication.PublicationState
import skirout.editor.v1.publication.PublicationStatus
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val RealmPublicationCoordinatorTest by testSuite {
    test("an outdated finding stays outdated while checking even when its authored witnesses still match") {
        val fixture = PublicationFixture()
        try {
            val witnesses =
                fixture.views.read { view ->
                    listOf(EditExpectation.createResource(id = PAGE_ID, expected = view.resources.getValue(PAGE_ID)))
                }
            fixture.findings =
                listOf(
                    fixture.findingSet(rule = 0, witnesses, FindingStatus.CURRENT),
                    fixture.findingSet(rule = 1, witnesses, FindingStatus.OUTDATED),
                )
            var observed: PublicationStatus.Checking? = null
            fixture.onEvaluate = { observed = (fixture.publisher.views.value.status as PublicationStatus.CheckingWrapper).value }

            fixture.publisher.refresh()

            observed!!.findings.map { it.status } shouldBe listOf(FindingStatus.CURRENT, FindingStatus.OUTDATED)
        } finally {
            fixture.close()
        }
    }

    test("preparing and unchanged content create no attempt or blob write") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        fixture.ready()
        fixture.results.latestReport() shouldBe null
        fixture.blobRequests shouldBe 0
        val released = fixture.release()
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.CurrentWrapper>()
        fixture.publisher.publish(PublicationCandidateId(value = "obsolete")) shouldBe PublicationResult.NoChanges
        fixture.results.latestReport()?.id shouldBe released.publication
        fixture.close()
    }

    test("unchanged assessment cannot repair or report an obsolete selected publication") {
        runTest {
            val fixture = PublicationFixture()
            try {
                val first = fixture.release().content
                val digest =
                    ArtifactDigest(
                        DigestAlgorithm.SHA_256,
                        first.outputs
                            .single()
                            .blob.digest,
                    )
                fixture.blobs.remove(digest)
                val assessing = CompletableDeferred<Unit>()
                val resume = CompletableDeferred<Unit>()
                fixture.onEvaluate = {
                    assessing.complete(Unit)
                    resume.await()
                }
                val refresh = async { fixture.publisher.refresh() }
                assessing.await()
                val replacement = first.copy(publication = PublicationId(value = "replacement"), outputs = emptyList())
                fixture.installElsewhere(replacement)
                val requests = fixture.blobRequests
                resume.complete(Unit)
                refresh.await()

                fixture.blobRequests shouldBe requests
                fixture.blobs.metadata(digest) shouldBe BlobResult.NotFound
                fixture.results.selected() shouldBe replacement
                fixture.publisher.views.value.status
                    .shouldBeInstanceOf<PublicationStatus.CheckingWrapper>()

                fixture.onEvaluate = null
                fixture.publisher.refresh()
                fixture.ready().baseline shouldBe PublicationBaseline.SelectedWrapper(replacement.publication)
            } finally {
                fixture.close()
            }
        }
    }

    test("initial empty content stays empty while removing the last root is a release") {
        val fixture = PublicationFixture(initial = emptyMap())
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.EmptyWrapper>()
        fixture.results.latestReport() shouldBe null
        fixture.update("Quest")
        fixture.release()
        fixture.views.install(fixture.views.prepare(AuthoringViewDelta(emptyMap(), removedResources = setOf(PAGE_ID))))
        fixture.publisher.refresh()
        val ready = fixture.ready()
        ready.changes.allChanges shouldBe listOf(PublicationChange.RootRemovedWrapper(fixture.root))
        fixture.publisher
            .publish(ready.candidate)
            .shouldBeInstanceOf<PublicationResult.Activated>()
            .content.outputs shouldBe emptyList()
        fixture.close()
    }

    test("an old candidate cannot start an attempt after another save or baseline change") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val old = fixture.ready()
        fixture.update("Story")
        fixture.publisher.publish(old.candidate).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.results.latestReport() shouldBe null
        fixture.blobRequests shouldBe 0
        fixture.publisher.refresh()
        (fixture.ready().candidate == old.candidate) shouldBe false
        val other = PublicationId(value = "other")
        fixture.installElsewhere(
            PublishedContent(
                publication = other,
                formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
                catalog = CatalogGeneration(value = "other"),
                implementationToken = "implementation",
                outputs = emptyList(),
            ),
        )
        fixture.publisher.publish(fixture.ready().candidate).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.results.latestReport()?.id shouldBe other
        fixture.close()
    }

    test("reverted edits leave the publication current without another attempt") {
        val fixture = PublicationFixture()
        val released = fixture.release()
        fixture.update("Story")
        fixture.publisher.refresh()
        fixture.ready()
        fixture.update("Quest")
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.CurrentWrapper>()
        fixture.results.latestReport()?.id shouldBe released.publication
        fixture.close()
    }

    test("a new catalog generation with identical definitions leaves the publication current without another attempt") {
        val fixture = PublicationFixture()
        val released = fixture.release()
        fixture.views.install(
            fixture.views.prepare(AuthoringViewDelta(catalog = PUBLICATION_CATALOG.lease(CatalogGeneration(value = "next")))),
        )
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.CurrentWrapper>()
            .value.selected shouldBe released.publication
        fixture.results.latestReport()?.id shouldBe released.publication
        fixture.close()
    }

    test("background findings revoke a candidate without a saved content change") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val old = fixture.ready().candidate
        fixture.publisher.invalidate()
        fixture.publisher.publish(old).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.results.latestReport() shouldBe null
        fixture.blobRequests shouldBe 0
        fixture.publisher.refresh()
        (fixture.ready().candidate == old) shouldBe false
        fixture.close()
    }

    test("missing saved content reports unavailable and can recover on the next refresh") {
        val fixture = PublicationFixture()
        fixture.captureFailure = true
        fixture.publisher.refresh()
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.UnavailableWrapper>()
        fixture.results.latestReport() shouldBe null
        fixture.captureFailure = false
        fixture.publisher.refresh()
        fixture.ready()
        fixture.close()
    }

    test("publication freezes reviewed bytes and later edits are compared with that release") {
        runTest {
            val fixture = PublicationFixture()
            fixture.publisher.refresh()
            val candidate = fixture.ready()
            val storing = CompletableDeferred<Unit>()
            val proceed = CompletableDeferred<Unit>()
            fixture.onStore = {
                storing.complete(Unit)
                proceed.await()
            }
            val first = async { fixture.publisher.publish(candidate.candidate) }
            storing.await()
            fixture.publisher.publish(candidate.candidate) shouldBe PublicationResult.Publishing
            fixture.update("Story")
            fixture.publisher.refresh()
            val active =
                fixture.publisher.views.value.status
                    .shouldBeInstanceOf<PublicationStatus.PublishingWrapper>()
                    .value
            active.next.confirmedChanges shouldBe listOf(PublicationChange.RootUpdatedWrapper(fixture.root))
            proceed.complete(Unit)
            val published = first.await().shouldBeInstanceOf<PublicationResult.Activated>()
            fixture.publishedPageValue(published.content) shouldBe DataValue.StringValueWrapper("Quest")
            fixture.publisher.refresh()
            fixture.ready().changes.allChanges shouldBe listOf(PublicationChange.RootUpdatedWrapper(fixture.root))
            fixture.results.latestReport()?.id shouldBe published.publication
            fixture.close()
        }
    }

    test("blocked compilation retains successful roots and source and target locations without effects") {
        val fixture = PublicationFixture(producers = listOf(ResourceGraphArtifactProducer, blockedProducer()))
        fixture.publisher.refresh()
        val blocked =
            fixture.publisher.views.value.status
                .shouldBeInstanceOf<PublicationStatus.BlockedWrapper>()
                .value
        blocked.confirmedChanges shouldBe listOf(PublicationChange.RootAddedWrapper(fixture.root))
        blocked.pendingRoots.single().resource shouldBe ResourceId(value = "broken")
        blocked.blockers.first.details.primary
            ?.resource shouldBe ResourceId(value = "broken")
        blocked.blockers.first.details.related
            .single()
            .resource shouldBe ResourceId(value = "target")
        fixture.results.latestReport() shouldBe null
        fixture.blobRequests shouldBe 0
        fixture.publisher.publish(PublicationCandidateId(value = "forged")).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.close()
    }

    test("engine requirements revoke a candidate before effects") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val candidate = fixture.ready()
        fixture.engineInputs = EngineImplementationInputs(token = InputToken(value = "new"))
        fixture.publisher.publish(candidate.candidate).shouldBeInstanceOf<PublicationResult.CandidateChanged>()
        fixture.results.latestReport() shouldBe null
        fixture.blobRequests shouldBe 0
        fixture.close()
    }

    test("engine requirements that change during activation record the attempt blocked with engine_inputs_changed and select nothing") {
        val fixture = PublicationFixture()
        fixture.publisher.refresh()
        val candidate = fixture.ready()
        fixture.onStore = { fixture.engineInputs = EngineImplementationInputs(token = InputToken(value = "new")) }

        fixture.publisher
            .publish(candidate.candidate)
            .shouldBeInstanceOf<PublicationResult.Blocked>()
            .blockers.first.details.code shouldBe "engine_inputs_changed"
        val report = fixture.results.latestReport()!!
        report.state
            .shouldBeInstanceOf<PublicationState.BlockedWrapper>()
            .value
            .map { it.code } shouldBe listOf("engine_inputs_changed")
        fixture.results.selected() shouldBe null
        fixture.close()
    }

    test("a failure while storing artifacts interrupts the attempt and keeps the previous selection") {
        val fixture = PublicationFixture()
        val released = fixture.release()
        fixture.update("Story")
        fixture.publisher.refresh()
        val candidate = fixture.ready()
        fixture.onStore = { error("Blob storage is unavailable.") }

        shouldThrow<IllegalStateException> { fixture.publisher.publish(candidate.candidate) }.message shouldBe
            "Blob storage is unavailable."

        val report = fixture.results.latestReport()!!
        report.state shouldBe PublicationState.INTERRUPTED
        fixture.publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.UnavailableWrapper>()
            .value.failure shouldBe PublicationFailure.PublicationInterruptedWrapper(report.id)
        fixture.results.selected() shouldBe released.content
        fixture.close()
    }

    test("recovery on start interrupts unfinished attempts and retains only the selected publication's blobs") {
        val fixture = PublicationFixture()
        val released = fixture.release()
        val unfinished = PublicationId(value = "unfinished")
        fixture.attempts.start(unfinished, released.content.catalog, testEngineInputs())
        fixture.attempts.phase(unfinished, PublicationState.ACTIVATING)
        fixture.retention.protect(unfinished.value, setOf(ArtifactDigest(DigestAlgorithm.SHA_256, "c".repeat(64))))

        fixture.publisher.recoverInterrupted()

        fixture.results.latestReport() shouldBe
            PublicationReport(id = unfinished, state = PublicationState.INTERRUPTED, findings = emptyList())
        fixture.results.selected() shouldBe released.content
        fixture.retention.selected shouldBe released.publication.value
        fixture.retention.publications shouldBe
            mapOf(
                released.publication.value to
                    setOf(
                        ArtifactDigest(
                            DigestAlgorithm.SHA_256,
                            released.content.outputs
                                .single()
                                .blob.digest,
                        ),
                    ),
            )
        fixture.close()
    }

    test("saved invalidation automatically replaces the immutable view and close stops observation") {
        runTest {
            val fixture = PublicationFixture()
            fixture.publisher.start(backgroundScope, fixture.views.changes)
            runCurrent()
            val first = fixture.publisher.views.value
            fixture.update("Story")
            runCurrent()
            (fixture.publisher.views.value.id == first.id) shouldBe false
            fixture.ready()
            fixture.publisher.close()
            val closed = fixture.publisher.views.value
            fixture.update("Later")
            runCurrent()
            fixture.publisher.views.value shouldBe closed
            fixture.close()
        }
    }

    test("a published resource graph artifact decodes to the authored resource graph") {
        val fixture = PublicationFixture()
        val released = fixture.release()

        fixture.publishedPageValue(released.content) shouldBe DataValue.StringValueWrapper("Quest")
        fixture.close()
    }
}

/**
 * A publication coordinator over saved views of the publication page catalog, assessed by production acceptance and
 * recorded in an embedded SurrealDB with the Realm schema. Hooks inject failures and pauses at the seams a test needs.
 */
internal class PublicationFixture(
    initial: Map<ResourceId, AuthoringRecord> = mapOf(PAGE_ID to publicationPageRecord("Quest")),
    producers: List<CompiledArtifactProducer> = listOf(ResourceGraphArtifactProducer),
) {
    val views = InMemoryAuthoringViewStore(PUBLICATION_CATALOG.lease(), AuthoringSeed(initial))
    private val checks = RealmCheckRuntime(views)
    private val database = publicationDatabase()
    val attempts = SurrealPublicationAttemptStore(database)
    val results = SurrealRegisteredCompiledContentRepository(database)
    val retention = TestPublicationRetention()
    val root = CompilationRoot(projection = CompilationProjectionId(value = "typewriter.resource-graph"), resource = PAGE_ID)
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

    fun ready() =
        publisher.views.value.status
            .shouldBeInstanceOf<PublicationStatus.ReadyWrapper>()
            .value

    fun update(value: String) = views.install(views.prepare(AuthoringViewDelta(mapOf(PAGE_ID to publicationPageRecord(value)))))

    suspend fun release(): PublicationResult.Activated {
        publisher.refresh()
        return publisher.publish(ready().candidate).shouldBeInstanceOf<PublicationResult.Activated>()
    }

    /** Selects [content] as another writer's completed publication would. */
    suspend fun installElsewhere(content: PublishedContent) {
        attempts.start(content.publication, content.catalog, testEngineInputs())
        attempts.phase(content.publication, PublicationState.ACTIVATING)
        attempts.install(content)
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
                .single { it.key.source == PAGE_ID }
        return (page.value.payload as DataValue.RecordWrapper).field("value")
    }

    /** A finding set of the page check numbered [rule], witnessed by [expectations] on the current catalog. */
    fun findingSet(
        rule: Int,
        expectations: List<EditExpectation>,
        status: FindingStatus,
    ): FindingSet {
        val location = ValueLocation.of(PAGE_ID)
        return FindingSet(
            ticket =
                CheckTicket(
                    instance =
                        CheckInstanceId(
                            rule = RuleId(origin = RuleOrigin(owner = PUBLICATION_PAGE, ordinal = 0), localIndex = rule),
                            location = location,
                        ),
                    incarnation = "external_input",
                    execution = CheckExecutionId(value = "execution"),
                    catalog = views.read { it.catalog.generation },
                ),
            expectations = expectations,
            outcome = CheckOutcome.FINISHED,
            findings = listOf(compilationDiagnostic("external_check", "An external input requires attention.", location = location)),
            status = status,
        )
    }

    suspend fun close() {
        publisher.close()
        checks.close()
        views.close()
        database.close()
    }
}

private fun blockedProducer() =
    object : CompiledArtifactProducer {
        override val projection = CompilationProjectionId(value = "fixture.blocked")
        override val mediaType = "application/blocked"

        override fun roots(view: AuthoringView) = setOf(CompilationRoot(projection = projection, resource = ResourceId(value = "broken")))

        context(inputs: CompilationInputs)
        override fun compile(roots: Set<CompilationRoot>): List<CompilationResult> =
            listOf(
                CompilationResult.Blocked(
                    roots.single(),
                    ContentDigest("a".repeat(64)),
                    listOf(
                        compilationDiagnostic(
                            "broken_link",
                            "The target is missing",
                            DiagnosticSeverity.ERROR,
                            ResourceId(value = "broken"),
                            ResourceId(value = "target"),
                        ),
                    ),
                ),
            )
    }

private fun publicationPageRecord(value: String) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(PUBLICATION_PAGE_USE),
        mapOf("value" to DataValue.StringValueWrapper(value)),
    )

private val PUBLICATION_PAGE = TypeDefinitionId.qualified("publication", "page")
private val PUBLICATION_PAGE_USE = PUBLICATION_PAGE.namedUse()
private val PUBLICATION_DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = CompilationUnitDefinition.id,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
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
                    abstract_ = false,
                ),
            parents = listOf(CompilationUnitDefinition.id.namedTemplate()),
        ),
    )

private val PAGE_ID = ResourceId(value = "page")

private val PUBLICATION_CATALOG =
    DefinitionCatalog(PUBLICATION_DEFINITIONS, nativeBindingFactories = listOf(recordBinding(PUBLICATION_PAGE)))
