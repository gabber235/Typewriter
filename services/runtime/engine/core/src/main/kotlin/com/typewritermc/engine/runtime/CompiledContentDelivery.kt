package com.typewritermc.engine.runtime

import com.typewritermc.authoring.PublicationId
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PublishedContentCodec
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.loader.api.realmEventAddress
import com.typewritermc.loader.api.realmRequestAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.skir.asPayloadCodec
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.communicator.transfer.BoundedByteTransferAssembler
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferChunk
import com.typewritermc.services.libs.communicator.transport.Payload
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import skirout.editor.v1.compiled_content.CompiledContentChanged
import skirout.editor.v1.compiled_content.QueryPublishedContent
import skirout.editor.v1.compiled_content.QueryPublishedContentRequest
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import java.util.UUID
import kotlin.time.Duration.Companion.seconds
import skirout.editor.v1.compiled_content.PublishedContent as WirePublishedContent

interface EngineContentDelivery {
    val health: StateFlow<EngineContentDeliveryHealth>

    fun start(apply: suspend (LoadedPublishedContent) -> Unit)

    suspend fun stop()
}

sealed interface EngineContentDeliveryHealth {
    data object Idle : EngineContentDeliveryHealth

    data object Watching : EngineContentDeliveryHealth

    data class Active(
        val publication: PublicationId,
    ) : EngineContentDeliveryHealth

    data class Failed(
        val message: String,
    ) : EngineContentDeliveryHealth
}

/** One worker fetches current descriptors after hints, reconnect, and periodic recovery. */
class MessagingEngineContentDelivery(
    private val host: HostedRuntimeHost,
    private val realmId: String,
    private val scope: CoroutineScope,
) : EngineContentDelivery {
    private val source = BlobCompiledArtifactSource(host.sharedArtifacts)
    private val mutableHealth = MutableStateFlow<EngineContentDeliveryHealth>(EngineContentDeliveryHealth.Idle)
    override val health: StateFlow<EngineContentDeliveryHealth> = mutableHealth
    private var worker: Job? = null

    override fun start(apply: suspend (LoadedPublishedContent) -> Unit) {
        check(worker == null) { "Compiled content delivery is already active" }
        worker =
            scope.launch {
                host.messaging.collectLatest { session ->
                    if (session == null) {
                        mutableHealth.value = EngineContentDeliveryHealth.Idle
                        return@collectLatest
                    }
                    coroutineScope {
                        val address = RealmServiceAddress(realmId, session.organizationId)
                        val hints = Channel<Unit>(Channel.CONFLATED)
                        val contract = compiledContentHints()
                        val router =
                            session.communicator.createRouter(
                                communicatorRoutes { eventAt(contract, address) { hints.trySend(Unit) } },
                                this,
                            )
                        try {
                            check(router.start() !is RouterResult.Failure) { "Could not subscribe to compiled content hints" }
                            while (currentCoroutineContext().isActive) {
                                mutableHealth.value = EngineContentDeliveryHealth.Watching
                                try {
                                    val content = fetchPublishedContent(session.communicator, address)
                                    if (content != null) {
                                        apply(source.load(content))
                                        mutableHealth.value = EngineContentDeliveryHealth.Active(content.publication)
                                    }
                                    withTimeoutOrNull(30.seconds) { hints.receive() }
                                } catch (cancelled: CancellationException) {
                                    throw cancelled
                                } catch (failure: Exception) {
                                    mutableHealth.value =
                                        EngineContentDeliveryHealth.Failed(failure.message ?: "Compiled content delivery failed")
                                    delay(1.seconds)
                                }
                            }
                        } finally {
                            router.stop()
                            hints.close()
                        }
                    }
                }
            }
    }

    override suspend fun stop() {
        worker?.cancelAndJoin()
        worker = null
        mutableHealth.value = EngineContentDeliveryHealth.Idle
    }
}

internal suspend fun fetchPublishedContent(
    communicator: Communicator,
    address: RealmServiceAddress,
): com.typewritermc.engine.PublishedContent? {
    val id = UUID.randomUUID().toString()
    val assembler = BoundedByteTransferAssembler(id)
    var content: com.typewritermc.engine.PublishedContent? = null
    withTimeout(30.seconds) {
        communicator.watch(publishedContentQuery(address), address, QueryPublishedContentRequest(transferId = id)).first { result ->
            when (result) {
                is CommunicationResult.Failure -> {
                    throw result.error.cause ?: IllegalStateException("Published content query failed")
                }

                is CommunicationResult.Success -> {
                    val response =
                        when (val message = result.value) {
                            is WatchMessage.Initial -> message.value
                            is WatchMessage.Update -> message.value
                        }
                    when (response) {
                        is QueryPublishedContentResponse.ChunkWrapper -> {
                            val chunk = response.value.transfer
                            val bytes =
                                assembler.accept(
                                    BoundedTransferChunk(
                                        chunk.transferId,
                                        chunk.index,
                                        chunk.chunkCount,
                                        chunk.encodedSize,
                                        chunk.sha256,
                                        Payload.copyOf(chunk.payload.toByteArray()),
                                    ),
                                )
                            if (bytes ==
                                null
                            ) {
                                false
                            } else {
                                content =
                                    PublishedContentCodec.decode(WirePublishedContent.serializer.fromBytes(okio.ByteString.of(*bytes)))
                                true
                            }
                        }

                        is QueryPublishedContentResponse.AbsentWrapper -> {
                            true
                        }

                        else -> {
                            error("Published content is unavailable")
                        }
                    }
                }
            }
        }
    }
    return content
}

private fun publishedContentQuery(address: RealmServiceAddress) =
    skirWatchContract(
        method = QueryPublishedContent,
        updateSerializer = QueryPublishedContentResponse.serializer,
        name = OperationName.of("editor.authoring.compiled.query"),
        requestAddress = "editor.authoring.compiled.query".realmRequestAddress().subscribedAt(address),
        updateAddress = "editor.authoring.compiled.query".realmEventAddress(),
        updateAddressResolver = { realm, request ->
            com.typewritermc.services.libs.communicator.address.MessageAddress.of(
                "editor.authoring.compiled.query".realmEventAddress().render(realm).value + "." + request.transferId,
            )
        },
        initialPolicy = ResponsePolicy(QueryPublishedContentResponse.createInternalError(), compiledContentResponseClassifier),
        updateClassifier = compiledContentResponseClassifier,
        failureSlug =
            com.typewritermc.services.libs.telemetry.ErrorSlug
                .of("compiled-content-query-failed"),
    )

private fun compiledContentHints() =
    EventContract(
        OperationName.of("editor.authoring.compiled.changed"),
        "editor.authoring.compiled.changed".realmEventAddress(),
        CompiledContentChanged.serializer.asPayloadCodec(),
        com.typewritermc.services.libs.telemetry.ErrorSlug
            .of("compiled-content-hint-failed"),
    )

private val compiledContentResponseClassifier =
    ResponseClassifier<QueryPublishedContentResponse> { response ->
        ResponseClassification(
            when (response) {
                is QueryPublishedContentResponse.ChunkWrapper, is QueryPublishedContentResponse.AbsentWrapper -> ResponseOutcome.SUCCESS
                is QueryPublishedContentResponse.InternalErrorWrapper -> ResponseOutcome.INTERNAL_ERROR
                else -> ResponseOutcome.DOMAIN_ERROR
            },
            ResponseVariant.of(response.kind.name.lowercase()),
        )
    }
