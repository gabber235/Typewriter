@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.artifact.ArtifactDigest
import com.typewritermc.loader.artifact.BlobEndpoint
import com.typewritermc.loader.artifact.BlobMetadata
import com.typewritermc.loader.artifact.DEFAULT_CHUNK_SIZE
import com.typewritermc.loader.artifact.TransferId
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.HostDeploymentProjectionCodec
import com.typewritermc.loader.deployment.HostId
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import kotlin.io.path.createDirectories
import kotlin.io.path.exists
import kotlin.io.path.readBytes
import kotlin.io.path.writeBytes

class BlobProjectionRepository(
    private val blobs: BlobEndpoint,
) : ProjectionRepository,
    ProjectionSource {
    override suspend fun publish(projection: HostDeploymentProjection): ProjectionReference {
        val bytes = HostDeploymentProjectionCodec.encode(projection)
        val digest = ArtifactDigest.sha256(bytes)
        if (blobs.metadata(digest) !is BlobResult.Success) {
            val transfer = TransferId.create()
            blobs.beginWrite(transfer, BlobMetadata(digest, bytes.size.toLong())).requireSuccess()
            var offset = 0
            while (offset < bytes.size) {
                val end = minOf(offset + DEFAULT_CHUNK_SIZE, bytes.size)
                blobs.write(transfer, offset.toLong(), bytes.copyOfRange(offset, end)).requireSuccess()
                offset = end
            }
            blobs.complete(transfer).requireSuccess()
        }
        return ProjectionReference(
            RealmId(projection.realmId),
            projection.generation,
            projection.hostId,
            digest,
            projection.runtimes.associate { it.placement to it.artifact.coordinate.version },
        )
    }

    override suspend fun fetch(reference: ProjectionReference): HostDeploymentProjection {
        val metadata = blobs.metadata(reference.blob).requireSuccess()
        require(metadata.size <= MAXIMUM_PROJECTION_SIZE) { "Deployment projection exceeds its maximum size." }
        val bytes = ByteArray(metadata.size.toInt())
        var offset = 0L
        while (offset < metadata.size) {
            val chunk = blobs.read(reference.blob, offset, DEFAULT_CHUNK_SIZE).requireSuccess()
            require(chunk.bytes.isNotEmpty()) { "Projection transfer ended before the declared blob size." }
            chunk.bytes.copyInto(bytes, offset.toInt())
            offset += chunk.bytes.size
        }
        require(ArtifactDigest.sha256(bytes) == reference.blob) { "Deployment projection digest does not match." }
        return HostDeploymentProjectionCodec.decode(bytes).also { projection ->
            require(projection.realmId == reference.realmId.value) { "Deployment projection belongs to another Realm." }
            require(projection.generation == reference.generation) { "Deployment projection generation does not match." }
            require(projection.hostId == reference.hostId) { "Deployment projection belongs to another host." }
        }
    }
}

class FileRolloutStateRepository(
    private val realmId: RealmId,
    artifactsRoot: Path,
) : RolloutStateRepository {
    private val mutex = Mutex()
    private val stateFile = artifactsRoot.resolve("rollout").resolve("${realmId.value}.cbor")
    private var stored = readRolloutState(stateFile)

    override suspend fun nextAttempt(generation: DeploymentGeneration): RolloutAttempt =
        updateWithResult { current ->
            val attempt = RolloutAttempt(current.lastAttemptOrdinal + 1, generation)
            current.copy(lastAttemptOrdinal = attempt.ordinal) to attempt
        }

    override suspend fun persist(rollout: PersistedRollout) = update { it.copy(rollout = rollout) }

    override suspend fun participantStatuses(attempt: RolloutAttempt): Map<HostId, ParticipantStatus> =
        mutex.withLock { stored.participants[attempt.ordinal].orEmpty() }

    override suspend fun committed(): CommittedDeployment? = mutex.withLock { stored.current }

    override suspend fun commit(deployment: CommittedDeployment) =
        update { current -> current.copy(previous = current.current, current = deployment) }

    override suspend fun record(event: ParticipantStateChanged) {
        if (event.realmId != realmId) return
        update { current ->
            val attempt = event.status.attempt.ordinal
            val statuses = current.participants[attempt].orEmpty() + (event.status.hostId to event.status)
            current.copy(participants = current.participants + (attempt to statuses))
        }
    }

    suspend fun current(): CommittedDeployment? = committed()

    suspend fun previous(): CommittedDeployment? = mutex.withLock { stored.previous }

    private suspend fun update(transform: (StoredRolloutState) -> StoredRolloutState) {
        mutex.withLock {
            stored = transform(stored)
            atomicWrite(stateFile, rolloutCbor.encodeToByteArray(StoredRolloutState.serializer(), stored))
        }
    }

    private suspend fun <Value> updateWithResult(transform: (StoredRolloutState) -> Pair<StoredRolloutState, Value>): Value =
        mutex.withLock {
            val (updated, result) = transform(stored)
            stored = updated
            atomicWrite(stateFile, rolloutCbor.encodeToByteArray(StoredRolloutState.serializer(), stored))
            result
        }
}

@Serializable
private data class StoredRolloutState(
    val lastAttemptOrdinal: Long = 0,
    val rollout: PersistedRollout? = null,
    val current: CommittedDeployment? = null,
    val previous: CommittedDeployment? = null,
    val participants: Map<Long, Map<HostId, ParticipantStatus>> = emptyMap(),
)

internal val rolloutCbor = Cbor { encodeDefaults = true }

private const val MAXIMUM_PROJECTION_SIZE = 4L * 1024L * 1024L

private fun <Value> BlobResult<Value>.requireSuccess(): Value =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("Blob was not found.")
        is BlobResult.Invalid -> error(reason)
        is BlobResult.Conflict -> error(reason)
    }

private fun readRolloutState(path: Path): StoredRolloutState =
    if (path.exists()) rolloutCbor.decodeFromByteArray(StoredRolloutState.serializer(), path.readBytes()) else StoredRolloutState()

private fun atomicWrite(
    path: Path,
    bytes: ByteArray,
) {
    path.parent.createDirectories()
    val temporary = path.resolveSibling("${path.fileName}.partial")
    temporary.writeBytes(bytes)
    try {
        Files.move(temporary, path, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
    } catch (_: java.nio.file.AtomicMoveNotSupportedException) {
        Files.move(temporary, path, StandardCopyOption.REPLACE_EXISTING)
    }
}
