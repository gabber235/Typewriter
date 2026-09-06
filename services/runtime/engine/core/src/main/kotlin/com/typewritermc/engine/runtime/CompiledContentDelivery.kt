package com.typewritermc.engine.runtime

import com.typewritermc.engine.ActivatedCompiledContent
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.engine.CompiledShardPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.loader.api.realmEventAddress
import com.typewritermc.loader.api.realmRequestAddress
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import skirout.library.v1.compiled_content.WatchCompiledContent
import skirout.library.v1.compiled_content.WatchCompiledContentRequest
import skirout.library.v1.compiled_content.WatchCompiledContentResponse

/**
 * Owns the subscription that brings compiled activations into an engine.
 *
 * [start] installs the application callback; [stop] must end delivery before activation resources are retired.
 * Delivery health describes this subscription separately from overall runtime health.
 */
interface EngineContentDelivery {
    val health: StateFlow<EngineContentDeliveryHealth>

    fun start(apply: suspend (ActivatedCompiledContent) -> Unit)

    suspend fun stop()
}

/**
 * Reports whether content delivery is idle, watching, successfully applied, or failed.
 *
 * Active records the applied activation revision. This state alone does not establish that player execution or
 * facet reconciliation exists.
 */
sealed interface EngineContentDeliveryHealth {
    data object Idle : EngineContentDeliveryHealth

    data object Watching : EngineContentDeliveryHealth

    data class Active(
        val activationRevision: Long,
    ) : EngineContentDeliveryHealth

    data class Failed(
        val message: String,
    ) : EngineContentDeliveryHealth
}

/**
 * Watches the Realm compiled content route through the host current messaging session.
 *
 * A session change cancels the previous watch. Activations are fetched and verified before invoking the callback;
 * failures are exposed through health and the watch is retried after a fixed delay. Start and stop require
 * serialized lifecycle access.
 */
class MessagingEngineContentDelivery(
    private val host: HostedRuntimeHost,
    private val realmId: String,
    private val scope: CoroutineScope,
) : EngineContentDelivery {
    private val source = BlobCompiledContentSource(host.sharedArtifacts)
    private val mutableHealth = MutableStateFlow<EngineContentDeliveryHealth>(EngineContentDeliveryHealth.Idle)
    override val health: StateFlow<EngineContentDeliveryHealth> = mutableHealth
    private var worker: Job? = null

    override fun start(apply: suspend (ActivatedCompiledContent) -> Unit) {
        check(worker == null) { "Compiled content delivery is already active." }
        worker =
            scope.launch {
                host.messaging.collectLatest { session ->
                    if (session == null) {
                        mutableHealth.value = EngineContentDeliveryHealth.Idle
                        return@collectLatest
                    }
                    val address = RealmServiceAddress(realmId, session.organizationId)
                    while (currentCoroutineContext().isActive) {
                        mutableHealth.value = EngineContentDeliveryHealth.Watching
                        try {
                            session.communicator
                                .watch(compiledContentWatch(address), address, WatchCompiledContentRequest())
                                .collect { result ->
                                    when (result) {
                                        is CommunicationResult.Failure -> {
                                            mutableHealth.value =
                                                EngineContentDeliveryHealth.Failed(
                                                    result.error.cause?.message
                                                        ?: "Compiled content watch failed without a cause.",
                                                )
                                        }

                                        is CommunicationResult.Success -> {
                                            val activation = result.value.activation()
                                            if (activation != null) {
                                                apply(source.load(activation.toDomain()))
                                                mutableHealth.value =
                                                    EngineContentDeliveryHealth.Active(
                                                        activation.activationRevision,
                                                    )
                                            }
                                        }
                                    }
                                }
                        } catch (error: CancellationException) {
                            throw error
                        } catch (error: Exception) {
                            mutableHealth.value =
                                EngineContentDeliveryHealth.Failed(
                                    error.message ?: "Compiled content delivery failed.",
                                )
                        }
                        delay(RETRY_DELAY_MILLIS)
                    }
                }
            }
    }

    /**
     * Cancels and joins the delivery worker, then resets health to idle.
     *
     * Await this before releasing resources used by the application callback.
     */
    override suspend fun stop() {
        worker?.cancelAndJoin()
        worker = null
        mutableHealth.value = EngineContentDeliveryHealth.Idle
    }

    private fun WatchMessage<WatchCompiledContentResponse, WatchCompiledContentResponse>.activation() =
        when (this) {
            is WatchMessage.Initial -> (value as? WatchCompiledContentResponse.InitialWrapper)?.value?.activation
            is WatchMessage.Update -> (value as? WatchCompiledContentResponse.ActivatedWrapper)?.value
        }

    private companion object {
        const val RETRY_DELAY_MILLIS = 1_000L
    }
}

private fun compiledContentWatch(address: RealmServiceAddress) =
    skirWatchContract(
        method = WatchCompiledContent,
        updateSerializer = WatchCompiledContentResponse.serializer,
        name = OperationName.of("compiled.content.watch"),
        requestAddress = realmRequestAddress("compiled.content.watch").subscribedAt(address),
        updateAddress = realmEventAddress("compiled.content.watch"),
        initialPolicy =
            ResponsePolicy(
                WatchCompiledContentResponse.createInternalError(message = "Compiled content watch failed"),
                compiledContentResponseClassifier,
            ),
        updateClassifier = compiledContentResponseClassifier,
        failureSlug = ErrorSlug.of("compiled-content-watch-failed"),
    )

private val compiledContentResponseClassifier =
    ResponseClassifier<WatchCompiledContentResponse> { response ->
        val outcome =
            when (response) {
                is WatchCompiledContentResponse.InitialWrapper,
                is WatchCompiledContentResponse.ActivatedWrapper,
                -> ResponseOutcome.SUCCESS

                is WatchCompiledContentResponse.InternalErrorWrapper -> ResponseOutcome.INTERNAL_ERROR

                else -> ResponseOutcome.DOMAIN_ERROR
            }
        ResponseClassification(outcome, ResponseVariant.of(response.kind.name.lowercase()))
    }

private fun skirout.library.v1.compiled_content.CompiledContentActivation.toDomain() =
    CompiledContentActivation(
        activationRevision = activationRevision,
        manifestDigest = ContentDigest(manifestDigest),
        manifest = manifest.toDomain(),
        shards = shards.map { CompiledShardPointer(ContentDigest(it.shardDigest), it.blob.toDomain()) },
    )

private fun skirout.library.v1.compiled_content.CompiledBlobPointer.toDomain() = CompiledBlobPointer(ContentDigest(digest), size)
