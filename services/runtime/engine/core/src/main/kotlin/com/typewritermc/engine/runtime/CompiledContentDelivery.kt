package com.typewritermc.engine.runtime

import com.typewritermc.authoring.PublicationId
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PublishedContentCodec
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledChanged
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import skirout.editor.v1.compiled_content.QueryPublishedContentRequest
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import kotlin.time.Duration.Companion.seconds

/**
 * Owns delivery work for one engine activation and serializes calls to its application callback.
 *
 * Start belongs to activation; stop must retire delivery before activation resources are released. Delivery
 * health describes synchronization with published content separately from the hosted runtime lifecycle.
 */
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

/**
 * Keeps an engine synchronized with the Realm selected publication through one worker per active session.
 *
 * Change events are conflated hints to refetch the current descriptor, never commands to apply event payloads.
 * The worker also fetches after session replacement and every thirty seconds, verifies referenced blobs,
 * and awaits application before fetching again. Ordinary fetch or application failures retry after one second;
 * stopping cancels and joins the worker before returning.
 */
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
                    while (currentCoroutineContext().isActive) {
                        try {
                            deliverSession(session, apply)
                        } catch (cancelled: CancellationException) {
                            throw cancelled
                        } catch (failure: Exception) {
                            mutableHealth.value =
                                EngineContentDeliveryHealth.Failed(
                                    failure.message ?: "Compiled content delivery failed",
                                )
                            delay(1.seconds)
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

    private suspend fun deliverSession(
        session: HostedMessagingSession,
        apply: suspend (LoadedPublishedContent) -> Unit,
    ) = coroutineScope {
        val address =
            RealmRouteScope(
                organizationId = session.organizationId,
                realmId = realmId,
            )
        val hints = Channel<Unit>(Channel.CONFLATED)
        val router =
            session.communicator.createRouter(
                communicatorRoutes {
                    eventAt(address.authoringCompiledChanged, address) { hints.trySend(Unit) }
                },
                this,
            )
        var primary: Throwable? = null
        try {
            router.start().requireDeliverySuccess("subscribe")
            while (currentCoroutineContext().isActive) {
                mutableHealth.value = EngineContentDeliveryHealth.Watching
                val content = fetchPublishedContent(session.communicator, address)
                if (content != null) {
                    apply(source.load(content))
                    mutableHealth.value = EngineContentDeliveryHealth.Active(content.publication)
                }
                withTimeoutOrNull(30.seconds) { hints.receive() }
            }
        } catch (failure: Throwable) {
            primary = failure
            throw failure
        } finally {
            try {
                withContext(NonCancellable) {
                    router.stop().requireDeliverySuccess("unsubscribe")
                }
            } catch (cleanup: Throwable) {
                val original = primary
                if (cleanup !is Exception || cleanup is CancellationException) {
                    if (original != null && original !== cleanup) cleanup.addSuppressed(original)
                    throw cleanup
                }
                if (original == null) throw cleanup
                if (original !== cleanup) original.addSuppressed(cleanup)
            } finally {
                hints.close()
            }
        }
    }
}

private fun RouterResult.requireDeliverySuccess(operation: String) {
    if (this is RouterResult.Failure) {
        throw IllegalStateException("Compiled content $operation failed", error.cause)
    }
}

/**
 * Fetches the descriptor of the selected publication, or null before any publication is selected.
 *
 * Transport failures, including replies the transport could not deliver complete, and internal error responses
 * throw, so the delivery worker retries after one second.
 */
internal suspend fun fetchPublishedContent(
    communicator: Communicator,
    address: RealmRouteScope,
): com.typewritermc.engine.PublishedContent? =
    when (val result = communicator.request(publishedContentQuery(address), address, QueryPublishedContentRequest())) {
        is CommunicationResult.Failure -> {
            throw result.error.cause ?: IllegalStateException("Published content query failed")
        }

        is CommunicationResult.Success -> {
            when (val response = result.value) {
                is QueryPublishedContentResponse.ContentWrapper -> PublishedContentCodec.decode(response.value)
                is QueryPublishedContentResponse.AbsentWrapper -> null
                else -> error("Published content is unavailable")
            }
        }
    }

private fun publishedContentQuery(address: RealmRouteScope) =
    address.authoringCompiledQuery(
        policy = ResponsePolicy(QueryPublishedContentResponse.createInternalError(), compiledContentResponseClassifier),
    )

private val compiledContentResponseClassifier =
    ResponseClassifier<QueryPublishedContentResponse> { response ->
        ResponseClassification(
            when (response) {
                is QueryPublishedContentResponse.ContentWrapper, is QueryPublishedContentResponse.AbsentWrapper -> ResponseOutcome.SUCCESS
                is QueryPublishedContentResponse.InternalErrorWrapper -> ResponseOutcome.INTERNAL_ERROR
                else -> ResponseOutcome.DOMAIN_ERROR
            },
            ResponseVariant.of(
                when (response) {
                    is QueryPublishedContentResponse.ContentWrapper -> "content"
                    is QueryPublishedContentResponse.AbsentWrapper -> "absent"
                    is QueryPublishedContentResponse.InternalErrorWrapper -> "internal-error"
                    else -> "unknown"
                },
            ),
        )
    }
