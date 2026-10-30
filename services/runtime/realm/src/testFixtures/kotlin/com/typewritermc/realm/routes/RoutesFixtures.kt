@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.requireValid
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.Page
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TagFields
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.operations.Delete
import com.typewritermc.operations.Duplicate
import com.typewritermc.operations.LinkWith
import com.typewritermc.operations.LinkWithDuplicate
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.LinkWithInputDefinition
import com.typewritermc.operations.MoveToOwner
import com.typewritermc.operations.MoveToOwnerInput
import com.typewritermc.operations.MoveToOwnerInputDefinition
import com.typewritermc.operations.Unlink
import com.typewritermc.operations.UnlinkInput
import com.typewritermc.operations.UnlinkInputDefinition
import com.typewritermc.operations.capability
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledChanged
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.protocol.transport.generated.authoringCompiledStatusQuery
import com.typewritermc.protocol.transport.generated.authoringEditCommit
import com.typewritermc.protocol.transport.generated.authoringPublicationQuery
import com.typewritermc.protocol.transport.generated.authoringPublish
import com.typewritermc.protocol.transport.generated.authoringSearch
import com.typewritermc.protocol.transport.generated.authoringStateQuery
import com.typewritermc.protocol.transport.generated.authoringTypeCommit
import com.typewritermc.protocol.transport.generated.authoringTypePreview
import com.typewritermc.protocol.transport.generated.editorCatalogFetch
import com.typewritermc.protocol.transport.generated.editorCatalogWatch
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.publication.CompiledArtifactProducerRegistry
import com.typewritermc.realm.publication.CompiledRootStatuses
import com.typewritermc.realm.publication.PublicationFixture
import com.typewritermc.realm.publication.ResourceGraphArtifactProducer
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.text
import com.typewritermc.realm.testing.value
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.setup.SetupHandle
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.FixtureCapabilities
import com.typewritermc.testing.routes.FixtureMessage
import com.typewritermc.testing.routes.fixtureGraphEntry
import com.typewritermc.testing.routes.fixtureGraphPage
import com.typewritermc.testing.routes.fixtureTimelineEntry
import com.typewritermc.testing.routes.fixtureTimelinePage
import com.typewritermc.testkit.CatalogEncoder
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.fieldMap
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.type
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.SearchAuthoringRequest
import skirout.editor.v1.authoring.SearchAuthoringResponse
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.capability.CapabilityInvocationRequest
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.capability.NotificationSeverity
import skirout.editor.v1.capability.PanelInstruction
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogInvalidated
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.catalog.WatchEditorCatalogResponse
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.compilation_root.CompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompilationStatusSelection
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.compiled_content.CompiledResourceState
import skirout.editor.v1.compiled_content.CompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusRequest
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse
import skirout.editor.v1.compiled_content.QueryPublishedContentRequest
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.operation.ResourceOperationId
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationCandidateId
import skirout.editor.v1.publication.PublishAuthoringRequest
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.QueryPublicationViewRequest
import skirout.editor.v1.publication.QueryPublicationViewResponse
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationSelectionEffect
import skirout.editor.v1.resource_operations.ResolveDropCandidatesResult
import skirout.editor.v1.resource_operations.ResolveResourceOperationsResult
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorOperator
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.InputToken
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValueLocation
import kotlin.time.Duration.Companion.seconds

/** The authoring routes of this Realm on the wire, committing through its own admission. */
internal fun RealmFixture.authoringRoutes(findings: () -> List<FindingSet> = { emptyList() }) =
    RouteFixture { address, _ -> communicatorRoutes { AuthoringRoutes(owner, views, findings, address = address).register(this) } }

internal suspend fun RouteFixture.state(generation: CatalogGeneration) =
    call(RealmRouteScope::authoringStateQuery, QueryAuthoringStateRequest(generation = generation))
        .shouldBeInstanceOf<QueryAuthoringStateResponse.StateWrapper>()
        .value

/**
 * Runs [test] against the search route of a Realm that has saved [book] under its current name, over a [StaleIndex]
 * that still lists [book] and the [removed] resource.
 */
internal suspend fun withSearch(
    book: skirout.kernel.v1.resource_id.ResourceId,
    removed: skirout.kernel.v1.resource_id.ResourceId,
    test: suspend RealmFixture.(RouteFixture) -> Unit,
) = RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), mapOf(book to record(name = "Readable Book"))).use { realm ->
    RouteFixture {
        address,
        _,
        ->
        communicatorRoutes { AuthoringSearchRoutes(StaleIndex(book, removed), realm.views, address).register(this) }
    }.use { wire -> realm.test(wire) }
}

/** Runs [test] against the catalog routes of a Realm that installed the catalog [generation]. */
internal suspend fun withCatalogRoutes(
    generation: String,
    test: suspend (RouteFixture) -> Unit,
) = RealmCatalogStore().use { catalogs ->
    catalogs.installTestCatalog(generation)
    RouteFixture { address, _ ->
        communicatorRoutes { EditorCatalogRoutes(RetainedRealmEditorCatalogSource(catalogs), UnusedInitialization, address).register(this) }
    }.use { wire -> test(wire) }
}

internal class HintConnection : AutoCloseable {
    val address = RealmRouteScope(organizationId = "organization", realmId = "realm")
    val transport = FakeMessageTransport()
    private val telemetry = TelemetryTestHarness.create()
    val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())

    fun editorUpdates(
        publication: PublicationFixture,
        scope: CoroutineScope,
    ) = EditorUpdatePublisher(publication.views, publication.publisher, emptyFlow(), telemetry.telemetry, scope)

    override fun close() {
        transport.close()
        telemetry.close()
    }
}

internal class BlockingPublishTransport(
    private val delegate: FakeMessageTransport = FakeMessageTransport(),
) : MessageTransport by delegate,
    AutoCloseable by delegate {
    val started = CompletableDeferred<Unit>()
    val cancelled = CompletableDeferred<Unit>()

    override suspend fun publish(message: OutboundMessage): TransportResult<Unit> {
        started.complete(Unit)
        try {
            awaitCancellation()
        } finally {
            cancelled.complete(Unit)
        }
    }
}

internal fun FakeMessageTransport.hints(): List<AuthoringChanged> =
    publications
        .filter { it.address.value.endsWith(".editor.authoring.changed") }
        .map { AuthoringChanged.serializer.fromBytes(it.payload.toByteArray()) }

internal suspend fun FakeMessageTransport.awaitCount(count: Int) =
    withTimeout(2.seconds) {
        while (hints().size < count) yield()
    }

/** Runs [test] against the publication, compiled content and compiled status routes of one [PublicationFixture]. */
internal suspend fun withPublicationRoutes(test: suspend (PublicationFixture, RouteFixture) -> Unit) {
    val publication = PublicationFixture()
    try {
        val statuses = CompiledRootStatuses(CompiledArtifactProducerRegistry(listOf(ResourceGraphArtifactProducer)), publication.results)
        RouteFixture { address, _ ->
            communicatorRoutes {
                PublicationRoutes(publication.publisher, address).register(this)
                EditorCompiledContentRoutes(publication.results, address).register(this)
                EditorCompiledResourceStatusRoutes(publication.views, statuses, address).register(this)
            }
        }.use { wire -> test(publication, wire) }
    } finally {
        publication.close()
    }
}

/** The route fixture capabilities installed in a Realm catalog, with valid requests for each of them. */
internal class Capabilities(
    private val source: RealmCapabilityInvocationSource,
    val message: (String) -> DataValue,
    val echo: CapabilityInvocationRequest,
    val announce: CapabilityInvocationRequest,
) {
    suspend fun computation(request: CapabilityInvocationRequest) = source.computation(request)

    suspend fun command(request: CapabilityInvocationRequest) = source.command(request)
}

internal fun capabilities(block: suspend Capabilities.() -> Unit) =
    runTest {
        RealmCatalogStore().use { catalogs ->
            catalogs.replace(routeFixtureCatalog.incarnation(GENERATION))
            catalogs.captureCurrent().use { lease ->
                val definitions = RealmCapabilityRegistry(lease.capabilities).definitions
                val computation = definitions.filterIsInstance<CapabilityDefinition.ComputationWrapper>().single().value
                val command = definitions.filterIsInstance<CapabilityDefinition.CommandWrapper>().single().value
                val encoder = CatalogEncoder(lease.checked, lease.nativeBindings)
                val message = { value: String -> encoder.encode(computation.requestType, FixtureMessage(value)) }

                fun request(id: CapabilityId) =
                    CapabilityInvocationRequest(
                        invocationId = InvocationId(value = "invocation"),
                        generation = CatalogGeneration(value = GENERATION),
                        capabilityId = id,
                        payload = message("hello"),
                        expectedResultType = null,
                    )
                Capabilities(
                    source = RealmCapabilityInvocationSource(catalogs),
                    message = message,
                    echo = request(computation.capabilityId).copy(expectedResultType = computation.resultType.toTemplate()),
                    announce = request(command.capabilityId),
                ).block()
            }
        }
    }

internal val List<Diagnostic>.messages get() = map(Diagnostic::message)

internal val CATALOG_INVALIDATE =
    MessageAddress.of("service.from.realm.organization.organization.realm.editor.catalog.invalidate")

/** The invalidation process of a Realm that installed [generation], on [scope]; [test] gets communicators from it. */
internal suspend fun withInvalidations(
    scope: CoroutineScope,
    generation: String,
    test: suspend InvalidationContext.(RealmCatalogInvalidationProcess) -> Unit,
) {
    val telemetry = TelemetryTestHarness.create()
    val catalogs = RealmCatalogStore().apply { installTestCatalog(generation) }
    // The retry waits in virtual time, so a long delay costs nothing and proves no wall clock is involved.
    val process =
        RealmCatalogInvalidationProcess(catalogs, scope, telemetry.telemetry, RetryPolicy.fixed(30.seconds), CoroutineDelayScheduler)
    val context = InvalidationContext(telemetry)
    try {
        context.test(process)
    } finally {
        process.stop()
        context.close()
        catalogs.close()
        telemetry.close()
    }
}

internal class InvalidationContext(
    private val telemetry: TelemetryTestHarness,
) : AutoCloseable {
    private val transports = mutableListOf<FakeMessageTransport>()

    fun communicator(transport: FakeMessageTransport): Communicator {
        transports += transport
        return Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
    }

    override fun close() = transports.forEach(FakeMessageTransport::close)
}

/** The generations announced on [this] transport, failed attempts included, in order. */
internal fun FakeMessageTransport.announcements(): List<String> =
    publications
        .filter { it.address == CATALOG_INVALIDATE }
        .map {
            CatalogInvalidated.serializer
                .fromBytes(it.payload.toByteArray())
                .generation.value
        }

/** A search over the candidates of [field] in the input of the operation object [operation], for dragging [subjects]. */
internal fun RealmFixture.candidateRequest(
    operation: ResourceOperationId,
    field: String,
    query: String,
    vararg subjects: skirout.kernel.v1.resource_id.ResourceId,
) = validSearchRequest().copy(
    generation = views.read { it.catalog.generation },
    capabilityId = CapabilityId(value = operations.candidateSearch(operation, field).value),
    resultType =
        com.typewritermc.operations.OperationResourceOptionDefinition.use
            .toTemplate()
            .template,
    operationContext = operations.searchContext(*subjects),
    query = RealmSearchQuery(normalizedQuery = query, terms = listOf(query), selectors = emptyList(), selectorExpression = null),
)

/** The simple names of the operation objects resolved for [targets]. */
internal fun RealmFixture.operationsOf(vararg targets: skirout.kernel.v1.resource_id.ResourceId): Set<String> =
    (operations.resolve(*targets) as ResolveResourceOperationsResult.ResolvedWrapper)
        .value.operations
        .mapTo(linkedSetOf()) { it.definition.id.simpleName }

/** Drop candidates for dragging [targets], by operation object simple name. */
internal fun RealmFixture.drops(vararg targets: skirout.kernel.v1.resource_id.ResourceId) =
    (operations.dropCandidates(*targets) as ResolveDropCandidatesResult.ResolvedWrapper)
        .value
        .associateBy { it.operation.declaration.substringAfterLast('.') }

/** Commits a MoveToOwner of [entry] into [page], optionally dropped at [anchor]. */
internal suspend fun RealmFixture.move(
    entry: SetupHandle<*>,
    page: SetupHandle<*>,
    anchor: PlacementAnchor? = null,
) = operations.commit(
    operations.prepare(
        operations.operation(MoveToOwner),
        entry.resource,
        input = operations.input(MoveToOwnerInput(page.id, anchor), MoveToOwnerInputDefinition.id),
    ),
)

/** Commits the link operation [operation] of [subject] with [input]. */
internal suspend fun RealmFixture.link(
    operation: Any,
    subject: SetupHandle<*>,
    input: Any,
) = operations.commit(
    operations.prepare(
        operations.operation(operation),
        subject.resource,
        input =
            operations.input(
                input,
                when (input) {
                    is LinkWithInput -> LinkWithInputDefinition.id
                    else -> UnlinkInputDefinition.id
                },
            ),
    ),
)

internal const val GENERATION = "capabilities"
