package com.typewritermc.realm.routes

import com.typewritermc.engine.PublishedContentCodec
import com.typewritermc.realm.compiler.PublicationResults
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.communicator.transfer.BoundedByteTransferEncoder
import com.typewritermc.services.libs.communicator.transfer.BoundedTransferPlan
import okio.ByteString.Companion.toByteString
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedContentChunk
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import skirout.kernel.v1.bounded_transfer.BoundedTransferChunk

/** Transfers one immutable descriptor of the currently selected complete publication. */
internal class EditorCompiledContentRoutes(
    private val content: PublicationResults,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.queryPublishedContent) { call ->
                val selected = content.selected()
                if (selected == null) {
                    QueryPublishedContentResponse.createAbsent()
                } else {
                    val bytes = PublishedContent.serializer.toBytes(PublishedContentCodec.encode(selected)).toByteArray()
                    when (val plan = BoundedByteTransferEncoder(nextTransferId = { call.request.transferId }).encode(bytes)) {
                        is BoundedTransferPlan.Unavailable -> {
                            QueryPublishedContentResponse.createUnavailable()
                        }

                        is BoundedTransferPlan.Ready -> {
                            val chunks =
                                plan.chunks.map { chunk ->
                                    QueryPublishedContentResponse.ChunkWrapper(
                                        PublishedContentChunk(
                                            transfer =
                                                BoundedTransferChunk(
                                                    transferId = chunk.transferId,
                                                    index = chunk.index,
                                                    chunkCount = chunk.chunkCount,
                                                    encodedSize = chunk.encodedSize,
                                                    sha256 = chunk.sha256,
                                                    payload = chunk.payload.toByteArray().toByteString(),
                                                ),
                                        ),
                                    )
                                }
                            chunks.drop(1).forEach { call.publishUpdate(it).requirePublished() }
                            chunks.first()
                        }
                    }
                }
            }
        }
}
