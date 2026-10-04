package com.typewritermc.realm.routes

import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.checking.FindingStatus
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken
import com.typewritermc.realm.authoring.AuthoredSnapshotRoot
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.absentInputToken
import com.typewritermc.realm.checking.CheckTicket
import com.typewritermc.realm.checking.FindingSet
import com.typewritermc.realm.checking.toWire
import com.typewritermc.realm.repository.AuthoringCommittedEvent
import com.typewritermc.realm.repository.AuthoringEventOutbox
import com.typewritermc.realm.repository.CommitDelta
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.transfer.BoundedByteTransferEncoder
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferChunk
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferPlan
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.getOrThrow
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import okio.ByteString.Companion.toByteString
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.authoring.AuthoringChangedTransferChunk
import skirout.editor.v1.authoring.AuthoringChangedTransferResult
import skirout.editor.v1.authoring.AuthoringFindingsReplacement
import skirout.editor.v1.authoring.AuthoringResource
import skirout.editor.v1.authoring.AuthoringResourceChange
import skirout.editor.v1.authoring.AuthoringTransferUnavailable
import skirout.editor.v1.authoring.AuthoringTransferUnavailableReason
import skirout.editor.v1.checking.FindingsToken
import skirout.editor.v1.type_catalog.BatchId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.SnapshotId
import java.security.MessageDigest
import skirout.editor.v1.authoring.LinkProjection as SkirLinkProjection
import skirout.editor.v1.authoring.RelationProjectionDelta as SkirRelationProjectionDelta
import skirout.editor.v1.catalog.ResourceDefinitionId as SkirResourceDefinitionId
import skirout.kernel.v1.bounded_transfer.BoundedTransferChunk as SkirBoundedTransferChunk

internal class EditorCheckEvents(
    private val snapshots: AuthoringSnapshotStore,
    private val outbox: AuthoringEventOutbox,
    private val scope: CoroutineScope,
) {
    private val lock = Mutex()
    private val sessionLock = Mutex()

    @Volatile
    private var publisher: Publisher? = null
    private var findings: () -> List<FindingSet> = { emptyList() }
    private var state: FindingState? = null
    private var pendingCheck: CheckTicket? = null
    private var activePublication: Deferred<Unit>? = null
    private val wakeups = Channel<Unit>(Channel.CONFLATED)
    private val drain: Job

    init {
        drain = scope.launch { runDrainLoop() }
    }

    fun bindFindings(provider: () -> List<FindingSet>) {
        findings = provider
    }

    fun configure(
        contracts: EditorContracts,
        address: RealmAddress,
        communicator: Communicator,
    ) {
        publisher = Publisher(communicator, contracts, address)
        kickOutbox()
    }

    suspend fun unconfigure() {
        val active =
            sessionLock.withLock {
                publisher = null
                activePublication.also { activePublication = null }
            }
        active?.cancelAndJoin()
    }

    suspend fun close() {
        unconfigure()
        wakeups.close()
        drain.cancelAndJoin()
    }

    suspend fun capture(root: AuthoredSnapshotRoot): CapturedFindings =
        lock.withLock {
            val current = state
            if (current?.snapshot == root.id && !current.captured.isUnknown()) {
                current.captured
            } else {
                captureCurrent(root).also { captured ->
                    if (current == null || current.snapshot == root.id) {
                        state = FindingState(root.id, captured)
                    }
                }
            }
        }

    fun committed() {
        kickOutbox()
    }

    suspend fun publishChanged(ticket: CheckTicket) {
        lock.withLock {
            pendingCheck = ticket
        }
        kickOutbox()
    }

    private fun kickOutbox() {
        wakeups.trySend(Unit)
    }

    private suspend fun runDrainLoop() {
        for (ignored in wakeups) {
            while (publisher != null) {
                try {
                    val pending = outbox.pending()
                    if (pending.isNotEmpty()) {
                        pending.forEach { event -> publishCommit(event) }
                        continue
                    }
                    val ticket = lock.withLock { pendingCheck } ?: break
                    if (!publishCheck(ticket)) break
                    lock.withLock {
                        if (pendingCheck == ticket) pendingCheck = null
                    }
                } catch (failure: CancellationException) {
                    throw failure
                } catch (_: Exception) {
                    delay(OUTBOX_RETRY_DELAY_MILLIS)
                }
            }
        }
    }

    private suspend fun publishCommit(event: AuthoringCommittedEvent) {
        val current = publisher ?: return
        val transition =
            lock.withLock {
                val previous =
                    state?.takeIf { it.snapshot == event.delta.previousSnapshot }
                        ?: FindingState(
                            event.delta.previousSnapshot,
                            CapturedFindings(emptyList(), unknownFindingsToken(event.delta.previousSnapshot)),
                        )
                val next = previous.captured.after(event.delta.inputTokens)
                FindingTransition(previous, next)
            }
        if (!publishTracked(current, event.toWire(transition.previous.captured, transition.next))) return
        outbox.acknowledge(event.batch)
        lock.withLock {
            if (state == null || state == transition.previous) {
                state = FindingState(event.delta.snapshot, transition.next)
            }
        }
    }

    private suspend fun publishCheck(ticket: CheckTicket): Boolean {
        val current = publisher ?: return false
        val event =
            snapshots.capture().use { snapshot ->
                val root = snapshot.root
                if (root.catalog.generation != ticket.catalog) return true
                lock.withLock {
                    val next = captureCurrent(root)
                    val previous =
                        state?.takeIf { it.snapshot == root.id }
                            ?: FindingState(root.id, next).also { state = it }
                    if (previous.captured == next) return true
                    AuthoringChanged(
                        previousSnapshot = SnapshotId(value = root.id.value),
                        snapshot = SnapshotId(value = root.id.value),
                        generation = CatalogGeneration(value = root.catalog.generation.value),
                        batch = BatchId(value = "checks:${ticket.execution.value}"),
                        resources = emptyList(),
                        relations = emptyRelations(),
                        previousFindings = previous.captured.token,
                        findingsToken = next.token,
                        findings = AuthoringFindingsReplacement(findings = next.findings),
                        changedObservations = emptyList(),
                    )
                }
            }
        if (!publishTracked(current, event)) return false
        lock.withLock {
            state =
                FindingState(
                    com.typewritermc.checking.SnapshotId(event.snapshot.value),
                    CapturedFindings(event.findings!!.findings, event.findingsToken),
                )
        }
        return true
    }

    private suspend fun publishTracked(
        expected: Publisher,
        event: AuthoringChanged,
    ): Boolean =
        coroutineScope {
            val operation = async(start = CoroutineStart.LAZY) { publish(expected, event) }
            val accepted =
                sessionLock.withLock {
                    if (publisher !== expected) return@withLock false
                    activePublication = operation
                    operation.start()
                    true
                }
            if (!accepted) return@coroutineScope false
            try {
                operation.await()
                true
            } catch (_: CancellationException) {
                currentCoroutineContext().ensureActive()
                false
            } finally {
                sessionLock.withLock {
                    if (activePublication === operation) activePublication = null
                }
            }
        }

    private fun captureCurrent(root: AuthoredSnapshotRoot): CapturedFindings = captureFindings(root, findings())

    private suspend fun publish(
        publisher: Publisher,
        event: AuthoringChanged,
    ) {
        val bytes = AuthoringChanged.serializer.toBytes(event).toByteArray()
        when (val plan = BoundedByteTransferEncoder().encode(bytes)) {
            is BoundedTransferPlan.Ready -> {
                plan.chunks.forEach { chunk ->
                    publisher.communicator
                        .publish(
                            publisher.contracts.authoringChanged,
                            publisher.address,
                            AuthoringChangedTransferResult.ChunkWrapper(
                                AuthoringChangedTransferChunk(
                                    generation = event.generation,
                                    previousSnapshot = event.previousSnapshot,
                                    snapshot = event.snapshot,
                                    previousFindings = event.previousFindings,
                                    findingsToken = event.findingsToken,
                                    transfer = chunk.toWire(),
                                ),
                            ),
                        ).requirePublished()
                }
            }

            is BoundedTransferPlan.Unavailable -> {
                publisher.communicator
                    .publish(
                        publisher.contracts.authoringChanged,
                        publisher.address,
                        AuthoringChangedTransferResult.UnavailableWrapper(
                            AuthoringTransferUnavailable(
                                generation = event.generation,
                                snapshot = event.snapshot,
                                reason = AuthoringTransferUnavailableReason.ENCODED_SIZE_LIMIT,
                                encodedSize = plan.encodedSize,
                                maxEncodedSize = plan.maxEncodedSize,
                            ),
                        ),
                    ).requirePublished()
            }
        }
    }

    private data class Publisher(
        val communicator: Communicator,
        val contracts: EditorContracts,
        val address: RealmAddress,
    )
}

internal data class CapturedFindings(
    val findings: List<skirout.editor.v1.checking.FindingSet>,
    val token: FindingsToken,
)

internal fun captureFindings(
    root: AuthoredSnapshotRoot,
    findings: List<FindingSet>,
): CapturedFindings = captureWireFindings(classifyFindings(root, findings))

private fun captureWireFindings(wire: List<skirout.editor.v1.checking.FindingSet>): CapturedFindings {
    val replacement = AuthoringFindingsReplacement(findings = wire)
    val digest =
        MessageDigest.getInstance("SHA-256").digest(
            AuthoringFindingsReplacement.serializer.toBytes(replacement).toByteArray(),
        )
    return CapturedFindings(wire, FindingsToken(value = digest.toHex()))
}

private fun classifyFindings(
    root: AuthoredSnapshotRoot,
    findings: List<FindingSet>,
): List<skirout.editor.v1.checking.FindingSet> {
    val absent = absentInputToken()
    return findings.map { set ->
        val status =
            if (set.observations.all { observation ->
                    (root.inputs[observation.identity] ?: absent) == observation.token
                }
            ) {
                FindingStatus.Current
            } else {
                FindingStatus.Outdated
            }
        set.copy(status = status).toWire()
    }
}

private data class FindingState(
    val snapshot: com.typewritermc.checking.SnapshotId,
    val captured: CapturedFindings,
)

private data class FindingTransition(
    val previous: FindingState,
    val next: CapturedFindings,
)

private fun unknownFindingsToken(snapshot: com.typewritermc.checking.SnapshotId): FindingsToken =
    FindingsToken(value = "unavailable:${snapshot.value}")

private fun AuthoringCommittedEvent.toWire(
    previous: CapturedFindings,
    next: CapturedFindings,
): AuthoringChanged =
    AuthoringChanged(
        previousSnapshot = SnapshotId(value = delta.previousSnapshot.value),
        snapshot = SnapshotId(value = delta.snapshot.value),
        generation = CatalogGeneration(value = delta.catalog.value),
        batch = BatchId(value = batch.value),
        resources = delta.resourceChanges(),
        relations = delta.relations.toWire(),
        previousFindings = previous.token,
        findingsToken = next.token,
        findings =
            if (previous.findings == next.findings) {
                null
            } else {
                AuthoringFindingsReplacement(findings = next.findings)
            },
        changedObservations =
            delta.inputTokens.entries
                .sortedBy { it.key.toString() }
                .map { (identity, token) ->
                    SkirAuthoringValueCodec.encode(InputObservation(identity, token)).getOrThrow()
                },
    )

private fun CapturedFindings.after(changed: Map<InputIdentity, InputToken>): CapturedFindings {
    if (changed.isEmpty() || findings.isEmpty() || isUnknown()) return this
    val next =
        findings.map { set ->
            val invalidated =
                set.observations.any { wire ->
                    val observation: InputObservation = SkirAuthoringValueCodec.decode(wire).getOrThrow()
                    changed[observation.identity]?.let { token -> token != observation.token } == true
                }
            if (invalidated) {
                set.copy(status = skirout.editor.v1.checking.FindingStatus.OUTDATED)
            } else {
                set
            }
        }
    return captureWireFindings(next)
}

private fun CapturedFindings.isUnknown(): Boolean = token.value.startsWith("unavailable:")

private fun CommitDelta.resourceChanges(): List<AuthoringResourceChange> =
    buildList {
        resources.entries.sortedBy { it.key.value }.forEach { (id, record) ->
            val definition = requireNotNull(resourceDefinitions[id])
            add(
                AuthoringResourceChange.UpsertWrapper(
                    AuthoringResource(
                        id = ResourceId(value = id.value),
                        definition = SkirResourceDefinitionId(value = definition.value),
                        content = SkirAuthoringValueCodec.encode(record).getOrThrow(),
                    ),
                ),
            )
        }
        removedResources.sortedBy { it.value }.forEach { id ->
            add(AuthoringResourceChange.RemoveWrapper(ResourceId(value = id.value)))
        }
    }

private fun RelationProjectionDelta.toWire(): SkirRelationProjectionDelta =
    SkirRelationProjectionDelta(
        removals = removed.map(LinkProjection::toWire),
        created = created.map(LinkProjection::toWire),
        metadataChanged = metadataChanged.map(LinkProjection::toWire),
    )

private fun LinkProjection.toWire(): SkirLinkProjection =
    SkirLinkProjection(
        contract =
            skirout.editor.v1.type_catalog
                .RelationId(value = contract.value),
        first = ResourceId(value = first.value),
        second = ResourceId(value = second.value),
        firstLocation = firstLocation?.let { SkirAuthoringValueCodec.encode(it).getOrThrow() },
        secondLocation = secondLocation?.let { SkirAuthoringValueCodec.encode(it).getOrThrow() },
    )

private fun BoundedTransferChunk.toWire(): SkirBoundedTransferChunk =
    SkirBoundedTransferChunk(
        transferId = transferId,
        index = index,
        chunkCount = chunkCount,
        encodedSize = encodedSize,
        sha256 = sha256,
        payload = payload.toByteArray().toByteString(),
    )

private fun emptyRelations(): SkirRelationProjectionDelta =
    SkirRelationProjectionDelta(
        removals = emptyList(),
        created = emptyList(),
        metadataChanged = emptyList(),
    )

private fun ByteArray.toHex(): String = joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }

private const val OUTBOX_RETRY_DELAY_MILLIS = 250L
