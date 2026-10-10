package com.typewritermc.services.libs.filetransfer.blob

import com.typewritermc.services.libs.filetransfer.TransferProtocolException
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

val BlobTransferTest by testSuite {
    test("verified reads reject missing metadata") {
        runTest {
            val endpoint = RecordingBlobEndpoint("content".encodeToByteArray())
            endpoint.metadataMissing = true

            shouldThrow<IllegalStateException> {
                endpoint.readVerified(endpoint.expected.digest, endpoint.expected.size)
            }
        }
    }

    test("verified reads reject metadata size disagreement") {
        runTest {
            val endpoint = RecordingBlobEndpoint("content".encodeToByteArray())

            shouldThrow<IllegalArgumentException> {
                endpoint.readVerified(endpoint.expected.digest, endpoint.expected.size + 1)
            }
        }
    }

    listOf(
        ReadFault.EMPTY_PROGRESS,
        ReadFault.OFFSET_MISMATCH,
        ReadFault.PREMATURE_COMPLETION,
        ReadFault.MISSING_COMPLETION,
    ).forEach { fault ->
        test("verified reads reject ${fault.description}") {
            runTest {
                val bytes =
                    if (fault == ReadFault.PREMATURE_COMPLETION) {
                        ByteArray(DEFAULT_CHUNK_SIZE + 1) { it.toByte() }
                    } else {
                        "content".encodeToByteArray()
                    }
                val endpoint = RecordingBlobEndpoint(bytes)
                endpoint.readFault = fault

                shouldThrow<TransferProtocolException> {
                    endpoint.readVerified(endpoint.expected.digest, endpoint.expected.size)
                }
            }
        }
    }

    test("verified reads reject digest disagreement") {
        runTest {
            val endpoint = RecordingBlobEndpoint("content".encodeToByteArray())
            endpoint.readBytes = "changed".encodeToByteArray()

            shouldThrow<IllegalArgumentException> {
                endpoint.readVerified(endpoint.expected.digest, endpoint.expected.size)
            }
        }
    }

    test("copy reuses an existing verified blob") {
        runTest {
            val source = RecordingBlobEndpoint("content".encodeToByteArray())
            val destination = RecordingBlobEndpoint(source.readBytes, initiallyCommitted = true)

            BlobTransfer().copyVerified(source, destination, source.expected.digest) shouldBe source.expected
            destination.beginCount shouldBe 0
        }
    }

    test("copy resumes at the destination accepted offset") {
        runTest {
            val source = RecordingBlobEndpoint("resume content".encodeToByteArray())
            val destination = RecordingBlobEndpoint(source.readBytes, initiallyCommitted = false)
            destination.pendingBytes = source.readBytes.copyOfRange(0, 4)

            BlobTransfer().copyVerified(source, destination, source.expected.digest) shouldBe source.expected
            destination.firstWriteOffset shouldBe 4
        }
    }

    test("copy rejects destination progress disagreement") {
        runTest {
            val source = RecordingBlobEndpoint("content".encodeToByteArray())
            val destination = RecordingBlobEndpoint(source.readBytes, initiallyCommitted = false)
            destination.writeOffsetAdjustment = 1

            shouldThrow<TransferProtocolException> {
                BlobTransfer().copyVerified(source, destination, source.expected.digest)
            }
        }
    }

    test("copy recovers when completion outcome is uncertain") {
        runTest {
            val source = RecordingBlobEndpoint("content".encodeToByteArray())
            val destination = RecordingBlobEndpoint(source.readBytes, initiallyCommitted = false)
            destination.uncertainCompletion = true

            BlobTransfer().copyVerified(source, destination, source.expected.digest) shouldBe source.expected
            destination.metadataQueries shouldBe 3
        }
    }
}

private enum class ReadFault(
    val description: String,
) {
    EMPTY_PROGRESS("empty progress"),
    OFFSET_MISMATCH("offset disagreement"),
    PREMATURE_COMPLETION("premature completion"),
    MISSING_COMPLETION("missing final completion"),
}

private class RecordingBlobEndpoint(
    bytes: ByteArray,
    initiallyCommitted: Boolean = true,
) : BlobEndpoint {
    val expected = BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong())
    var readBytes = bytes.copyOf()
    var metadataMissing = false
    var readFault: ReadFault? = null
    var pendingBytes = byteArrayOf()
    var writeOffsetAdjustment = 0L
    var uncertainCompletion = false
    var beginCount = 0
    var firstWriteOffset: Long? = null
    var metadataQueries = 0
    private var committed = initiallyCommitted
    private var activeTransfer: TransferId? = null

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> {
        metadataQueries++
        return if (!metadataMissing && committed && digest == expected.digest) {
            BlobResult.Success(expected)
        } else {
            BlobResult.NotFound
        }
    }

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> {
        if (digest != expected.digest) return BlobResult.NotFound
        if (readFault == ReadFault.EMPTY_PROGRESS) return BlobResult.Success(BlobChunk(offset, byteArrayOf(), false))
        val start = offset.toInt().coerceAtMost(readBytes.size)
        val end = minOf(readBytes.size, start + maximumBytes)
        val reportedOffset = if (readFault == ReadFault.OFFSET_MISMATCH) offset + 1 else offset
        val complete =
            when (readFault) {
                ReadFault.PREMATURE_COMPLETION -> true
                ReadFault.MISSING_COMPLETION -> false
                else -> end == readBytes.size
            }
        return BlobResult.Success(BlobChunk(reportedOffset, readBytes.copyOfRange(start, end), complete))
    }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> {
        beginCount++
        activeTransfer = transfer
        return BlobResult.Success(BlobWriteSession(transfer, expected, pendingBytes.size.toLong()))
    }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> {
        if (transfer != activeTransfer || offset != pendingBytes.size.toLong()) return BlobResult.NotFound
        if (firstWriteOffset == null) firstWriteOffset = offset
        pendingBytes += bytes
        return BlobResult.Success(pendingBytes.size.toLong() + writeOffsetAdjustment)
    }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> {
        if (transfer != activeTransfer) return BlobResult.NotFound
        if (pendingBytes.contentEquals(readBytes)) committed = true
        return if (uncertainCompletion) BlobResult.NotFound else BlobResult.Success(expected)
    }
}
