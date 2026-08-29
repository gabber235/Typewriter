package com.typewritermc.realm.routes

import build.skir.Serializer
import com.typewritermc.realm.compiler.SurrealCompiledContentRepository
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.RepositoryFixture
import com.typewritermc.realm.repository.SurrealLibraryBatchRepository
import com.typewritermc.realm.repository.SurrealPageDocumentRepository
import com.typewritermc.realm.testPageCatalog
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import java.time.Instant
import kotlin.time.Duration.Companion.seconds

internal class RouteFixture(
    editorCatalog: RealmEditorCatalogSource = UnavailableRealmEditorCatalogSource(),
    presentationSearch: RealmPresentationSearchSource = UnavailableRealmPresentationSearchSource(),
    decorateBooks: (BookRepository) -> BookRepository = { it },
) : AutoCloseable {
    val repositories = RepositoryFixture()
    val compiledContent = SurrealCompiledContentRepository(repositories.database)
    val transport = FakeMessageTransport()
    private val telemetry = TelemetryTestHarness.create()
    private val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val router: CommunicatorRouter =
        communicator.createRouter(
            RealmRouteFactory(
                decorateBooks(repositories.books),
                repositories.pages,
                repositories.tags,
                SurrealLibraryBatchRepository(repositories.database),
                repositories.elements,
                repositories.elementTypeGraphs,
                SurrealPageDocumentRepository(repositories.database) { null },
                compiledContent,
                editorCatalog,
                testPageCatalog(),
                presentationSearch,
            ).create(RealmAddress("realm", "organization")),
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
        publishOutbox()
        return responseSerializer.fromBytes(publication.message.payload.toByteArray())
    }

    private suspend fun publishOutbox() {
        while (true) {
            val pending = repositories.outbox.pending(100)
            if (pending.isEmpty()) return
            pending.forEach { row ->
                communicator.publishEncoded(row.event)
                repositories.outbox.markPublished(row.id, Instant.now())
            }
        }
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
        try {
            runBlocking { router.stop() }
            scope.cancel()
            transport.close()
            telemetry.close()
        } finally {
            repositories.close()
        }
    }
}
