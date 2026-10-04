package com.typewritermc.realm.routes

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.services.libs.communicator.transfer.BoundedByteTransferEncoder
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferChunk
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferLimits
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferPlan
import com.typewritermc.types.catalog.toWire
import okio.ByteString.Companion.toByteString
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogInvalidated
import skirout.editor.v1.catalog.CatalogUnavailableReason
import skirout.editor.v1.catalog.EditorCatalogWireSnapshot
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.type_catalog.CatalogGeneration as WireCatalogGeneration
import skirout.kernel.v1.bounded_transfer.BoundedTransferChunk as WireBoundedTransferChunk

interface RealmEditorCatalogSource {
    suspend fun fetch(request: CatalogFetchRequest): EditorCatalogTransfer

    suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogInvalidated
}

data class EditorCatalogTransfer(
    val initial: CatalogFetchResult,
    val updates: List<CatalogFetchResult>,
)

class SnapshotRealmEditorCatalogSource(
    private val catalogs: RealmCatalogStore,
    chunkSize: Int = DEFAULT_CATALOG_CHUNK_SIZE,
    maxChunks: Int = MAX_CATALOG_CHUNKS,
) : RealmEditorCatalogSource {
    private val limits = BoundedTransferLimits(chunkSize, maxChunks)

    override suspend fun fetch(request: CatalogFetchRequest): EditorCatalogTransfer =
        catalogs.captureCurrent().use { catalog ->
            val expected = request.expectedGeneration?.value?.let(::CatalogGeneration)
            if (expected != null && expected != catalog.generation) {
                EditorCatalogTransfer(
                    CatalogFetchResult.GenerationChangedWrapper(WireCatalogGeneration(value = catalog.generation.value)),
                    emptyList(),
                )
            } else {
                catalog.editorSnapshot.toWire().toCatalogTransfer(request.transferId)
            }
        }

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogInvalidated =
        catalogs.captureCurrent().use { catalog ->
            CatalogInvalidated(generation = WireCatalogGeneration(value = catalog.generation.value))
        }

    private fun EditorCatalogWireSnapshot.toCatalogTransfer(transferId: String): EditorCatalogTransfer {
        val encoded = EditorCatalogWireSnapshot.serializer.toBytes(this).toByteArray()
        return when (val plan = BoundedByteTransferEncoder(limits) { transferId }.encode(encoded)) {
            is BoundedTransferPlan.Unavailable -> {
                EditorCatalogTransfer(
                    CatalogFetchResult.createUnavailable(
                        generation = generation,
                        reason = CatalogUnavailableReason.ENCODED_SIZE_LIMIT,
                        encodedSize = plan.encodedSize,
                        maxEncodedSize = plan.maxEncodedSize,
                    ),
                    emptyList(),
                )
            }

            is BoundedTransferPlan.Ready -> {
                val results =
                    plan.chunks.map { chunk ->
                        CatalogFetchResult.createChunk(
                            generation = generation,
                            transfer = chunk.toWire(),
                        )
                    }
                EditorCatalogTransfer(results.first(), results.drop(1))
            }
        }
    }
}

private const val DEFAULT_CATALOG_CHUNK_SIZE = 512 * 1024
private const val MAX_CATALOG_CHUNKS = 64

private fun BoundedTransferChunk.toWire(): WireBoundedTransferChunk =
    WireBoundedTransferChunk(
        transferId = transferId,
        index = index,
        chunkCount = chunkCount,
        encodedSize = encodedSize,
        sha256 = sha256,
        payload = payload.toByteArray().toByteString(),
    )
