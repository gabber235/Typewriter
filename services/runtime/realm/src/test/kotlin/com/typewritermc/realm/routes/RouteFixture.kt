package com.typewritermc.realm.routes

import build.skir.Serializer
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.realm.RealmAuthoringPolicyAssembler
import com.typewritermc.realm.compiler.RegisteredCompiledContentRepository
import com.typewritermc.realm.compiler.RegisteredCompiledState
import com.typewritermc.realm.repository.AuthoringBatch
import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringGraphRepository
import com.typewritermc.realm.repository.AuthoringGraphSnapshot
import com.typewritermc.realm.repository.AuthoringOperation
import com.typewritermc.realm.repository.AuthoringPreviewResult
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.GraphSelection
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypePrototypeRegistry
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import kotlin.time.Duration.Companion.seconds

internal class RouteFixture(
    editorCatalog: RealmEditorCatalogSource = UnavailableRealmEditorCatalogSource(),
    presentationSearch: RealmPresentationSearchSource = UnavailableRealmPresentationSearchSource(),
    authoring: AuthoringRepository = EmptyAuthoringRepository,
    onCompilationInvalidated: (List<CompilationRoot>) -> Unit = {},
) : AutoCloseable {
    val compiledContent: RegisteredCompiledContentRepository = EmptyCompiledContentRepository()
    val transport = FakeMessageTransport()
    private val telemetry = TelemetryTestHarness.create()
    private val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val router: CommunicatorRouter =
        communicator.createRouter(
            RealmRouteFactory(
                authoring = authoring,
                authoringGraph = EmptyAuthoringGraphRepository,
                compiledContent = compiledContent,
                editorCatalog = editorCatalog,
                presentationSearch = presentationSearch,
                onCompilationInvalidated = onCompilationInvalidated,
                prototypes = TypePrototypeRegistry(emptyList()),
                authoringPolicies = RealmAuthoringPolicyAssembler.assemble(emptyList(), TypeCatalog(emptyList())),
            ).create(RealmAddress("realm", "organization"), communicator),
            scope,
        )
    private var replySequence = 0

    init {
        runBlocking { router.start() shouldBe RouterResult.Success }
    }

    suspend fun <Request : Any, Response : Any> request(
        suffix: String,
        request: Request,
        requestSerializer: Serializer<Request>,
        responseSerializer: Serializer<Response>,
    ): Response {
        val reply = MessageAddress.of("test.reply.${replySequence++}")
        transport.deliver(
            TransportDelivery.Message(
                InboundMessage(
                    address =
                        MessageAddress.of(
                            "service.to.realm.organization.organization.realm.$suffix",
                        ),
                    payload = requestSerializer.toBytes(request).toByteArray(),
                    replyTo = reply,
                ),
            ),
        )
        val publication =
            withTimeout(2.seconds) {
                while (true) {
                    transport.actions
                        .filterIsInstance<FakeMessageTransport.Action.Publish>()
                        .lastOrNull { it.message.address == reply }
                        ?.let { return@withTimeout it }
                    yield()
                }
                error("Reply wait ended unexpectedly")
            }
        return responseSerializer.fromBytes(publication.message.payload.toByteArray())
    }

    fun publishedTo(suffix: String) =
        transport.actions
            .filterIsInstance<FakeMessageTransport.Action.Publish>()
            .filter {
                it.message.address ==
                    MessageAddress.of(
                        "service.from.realm.organization.organization.realm.$suffix",
                    )
            }

    fun <Response : Any> publishedTo(
        suffix: String,
        serializer: Serializer<Response>,
    ): List<Response> = publishedTo(suffix).map { serializer.fromBytes(it.message.payload.toByteArray()) }

    override fun close() {
        runBlocking { router.stop() }
        scope.cancel()
        transport.close()
        telemetry.close()
    }
}

private object EmptyAuthoringRepository : AuthoringRepository {
    override suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult = AuthoringBatchResult.Invalid(emptyList())

    override suspend fun preview(
        generation: String,
        operations: List<AuthoringOperation>,
    ): AuthoringPreviewResult = AuthoringPreviewResult.Invalid(emptyList())
}

private object EmptyAuthoringGraphRepository : AuthoringGraphRepository {
    override suspend fun query(
        generation: String,
        selections: List<GraphSelection>,
    ): AuthoringGraphQueryResult =
        AuthoringGraphQueryResult.Success(
            AuthoringGraphSnapshot(generation, 0, emptyList(), emptyList(), emptyList()),
        )
}

private class EmptyCompiledContentRepository : RegisteredCompiledContentRepository {
    override suspend fun activeManifest(): CompiledArtifactManifest? = null

    override suspend fun activeActivation(): CompiledArtifactActivation? = null

    override suspend fun nextActivationRevision(): Long = 1

    override suspend fun states(roots: Set<CompilationRoot>): Map<CompilationRoot, RegisteredCompiledState> =
        roots.associateWith { RegisteredCompiledState.NotCompiled }

    override suspend fun recordBlocked(
        sourceRevision: String,
        catalogRevision: String,
        roots: Collection<CompilationRoot>,
        diagnostics: List<CompileDiagnostic>,
    ) = true

    override suspend fun publish(
        manifest: CompiledArtifactManifest,
        artifacts: Collection<CompiledArtifact>,
        activation: CompiledArtifactActivation,
    ): Boolean = true
}
