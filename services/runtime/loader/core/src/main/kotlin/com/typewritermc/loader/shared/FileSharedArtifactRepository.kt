@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.loader.shared

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

/**
 * Stores descriptors, catalog revision, and pending events together in a CBOR state file.
 *
 * A mutex serializes this instance. Failed transaction blocks discard working changes; file replacement uses
 * atomic moves when supported. A persistence failure can leave memory advanced and propagates to the caller. This
 * is not a multiprocess database.
 */
class FileSharedArtifactRepository(
    private val stateFile: Path,
) : SharedArtifactRepository {
    private val mutex = Mutex()
    private var state = readState(stateFile)

    override suspend fun <Value> transaction(block: suspend SharedArtifactTransaction.() -> Value): Value =
        mutex.withLock {
            val working = MutableTransaction(state)
            val value = working.block()
            state = working.state()
            writeState(stateFile, state)
            value
        }

    override suspend fun catalog(): SharedArtifactCatalog =
        mutex.withLock {
            SharedArtifactCatalog(
                SharedCatalogRevision(state.catalogRevision),
                state.artifacts.sortedBy { it.id.value },
            )
        }

    suspend fun pendingChanges(): List<SharedArtifactChanged> = mutex.withLock { state.outbox }

    /**
     * Removes a pending event after successful publication.
     *
     * Acknowledgment is separate from delivery; interruption between them can cause duplicate events.
     */
    suspend fun acknowledge(change: SharedArtifactChanged) {
        mutex.withLock {
            state = state.copy(outbox = state.outbox.filterNot { it == change })
            writeState(stateFile, state)
        }
    }

    private class MutableTransaction(
        initial: StoredSharedArtifacts,
    ) : SharedArtifactTransaction {
        private val artifacts = initial.artifacts.associateByTo(linkedMapOf()) { it.id }
        private var catalogRevision = initial.catalogRevision
        private val outbox = initial.outbox.toMutableList()

        override suspend fun find(id: SharedArtifactId): SharedArtifactDescriptor? = artifacts[id]

        override suspend fun save(descriptor: SharedArtifactDescriptor) {
            artifacts[descriptor.id] = descriptor
        }

        override suspend fun nextCatalogRevision(): SharedCatalogRevision = SharedCatalogRevision(++catalogRevision)

        override suspend fun enqueue(change: SharedArtifactChanged) {
            outbox += change
        }

        fun state() = StoredSharedArtifacts(catalogRevision, artifacts.values.toList(), outbox)
    }
}

@Serializable
private data class StoredSharedArtifacts(
    val catalogRevision: Long = 0,
    val artifacts: List<SharedArtifactDescriptor> = emptyList(),
    val outbox: List<SharedArtifactChanged> = emptyList(),
)

private val sharedArtifactCbor = Cbor { encodeDefaults = true }

private fun readState(path: Path): StoredSharedArtifacts =
    if (path.exists()) {
        sharedArtifactCbor.decodeFromByteArray(StoredSharedArtifacts.serializer(), path.readBytes())
    } else {
        StoredSharedArtifacts()
    }

private fun writeState(
    path: Path,
    state: StoredSharedArtifacts,
) {
    path.parent.createDirectories()
    val temporary = path.resolveSibling("${path.fileName}.partial")
    temporary.writeBytes(sharedArtifactCbor.encodeToByteArray(StoredSharedArtifacts.serializer(), state))
    try {
        Files.move(temporary, path, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
    } catch (_: java.nio.file.AtomicMoveNotSupportedException) {
        Files.move(temporary, path, StandardCopyOption.REPLACE_EXISTING)
    }
}
