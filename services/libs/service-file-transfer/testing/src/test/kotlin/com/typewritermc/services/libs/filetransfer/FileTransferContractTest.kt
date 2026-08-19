package com.typewritermc.services.libs.filetransfer

import com.typewritermc.services.libs.filetransfer.messaging.FileTransferMessageChannel
import com.typewritermc.services.libs.filetransfer.messaging.FileTransferMessageHandler
import com.typewritermc.services.libs.filetransfer.messaging.MessagingFileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.storage.FileSystemFileTransferEndpoint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.ints.shouldBeLessThanOrEqual
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import java.security.MessageDigest

val FileTransferContractTest by testSuite {
    listOf("local" to ::localFixture, "messaging" to ::messagingFixture).forEach { (adapter, fixture) ->
        test("$adapter adapter uploads and downloads immutable content") {
            runTest {
                val environment = fixture()
                val bytes = "generic file transfer".encodeToByteArray()
                environment.source.import(fileKey, bytes).shouldSucceed()

                val uploaded =
                    coordinator.upload(TransferId.of("upload.$adapter"), fileKey, environment.source, environment.subject)
                uploaded.shouldSucceed().size shouldBe bytes.size.toLong()

                val destination = FileSystemFileTransferEndpoint(Files.createTempDirectory("file-transfer-download"))
                coordinator.download(TransferId.of("download.$adapter"), fileKey, environment.subject, destination).shouldSucceed()
                destination
                    .readAll(fileKey)
                    .shouldSucceed()
                    .contentEquals(bytes)
                    .shouldBeTrue()
            }
        }

        test("$adapter adapter resumes from the accepted offset") {
            runTest {
                val environment = fixture()
                val bytes = "resume this transfer".encodeToByteArray()
                val metadata = environment.source.import(fileKey, bytes).shouldSucceed()
                val transferId = TransferId.of("resume.$adapter")
                environment.subject
                    .beginWrite(transferId, metadata)
                    .shouldSucceed()
                    .acceptedOffset shouldBe 0
                environment.subject.write(transferId, 0, bytes.copyOfRange(0, 4)).shouldSucceed() shouldBe 4

                coordinator.transfer(transferId, fileKey, environment.source, environment.subject).shouldSucceed()
                environment.remote
                    .readAll(fileKey)
                    .shouldSucceed()
                    .contentEquals(bytes)
                    .shouldBeTrue()
            }
        }

        test("$adapter adapter cancels partial transfers") {
            runTest {
                val environment = fixture()
                val bytes = "cancel this transfer".encodeToByteArray()
                val metadata = environment.source.import(fileKey, bytes).shouldSucceed()
                val transferId = TransferId.of("cancel.$adapter")
                environment.subject.beginWrite(transferId, metadata).shouldSucceed()
                environment.subject.write(transferId, 0, bytes.copyOfRange(0, 3)).shouldSucceed()
                environment.subject.cancel(transferId).shouldSucceed()

                environment.subject
                    .beginWrite(transferId, metadata)
                    .shouldSucceed()
                    .acceptedOffset shouldBe 0
            }
        }

        test("$adapter adapter enforces bounded chunks") {
            runTest {
                val environment = fixture()
                val bytes = "bounded chunks".encodeToByteArray()
                environment.source.import(fileKey, bytes).shouldSucceed()
                val recording = RecordingEndpoint(environment.subject)

                coordinator.transfer(TransferId.of("bounded.$adapter"), fileKey, environment.source, recording).shouldSucceed()

                recording.chunkSizes.shouldContainExactly(3, 3, 3, 3, 2)
                recording.chunkSizes.forEach { it shouldBeLessThanOrEqual 3 }
            }
        }

        test("$adapter adapter rejects digest mismatches") {
            runTest {
                val environment = fixture()
                val bytes = "verify this transfer".encodeToByteArray()
                environment.source.import(fileKey, bytes).shouldSucceed()
                val corruptMetadataSource = InvalidDigestEndpoint(environment.source)

                val result =
                    coordinator.transfer(
                        TransferId.of("digest.$adapter"),
                        fileKey,
                        corruptMetadataSource,
                        environment.subject,
                    )

                result
                    .shouldBeInstanceOf<FileTransferResult.Failure>()
                    .error
                    .shouldBeInstanceOf<FileTransferError.DigestMismatch>()
            }
        }

        test("$adapter adapter rejects replacement of immutable revisions") {
            runTest {
                val environment = fixture()
                environment.source.import(fileKey, "first".encodeToByteArray()).shouldSucceed()
                coordinator
                    .transfer(TransferId.of("immutable.first.$adapter"), fileKey, environment.source, environment.subject)
                    .shouldSucceed()
                val replacement = FileSystemFileTransferEndpoint(Files.createTempDirectory("file-transfer-replacement"))
                replacement.import(fileKey, "second".encodeToByteArray()).shouldSucceed()

                val result =
                    coordinator.transfer(
                        TransferId.of("immutable.second.$adapter"),
                        fileKey,
                        replacement,
                        environment.subject,
                    )

                result shouldBe FileTransferResult.Failure(FileTransferError.ImmutableConflict(fileKey))
            }
        }
    }

    test("local storage does not expose objects before metadata publication") {
        runTest {
            val root = Files.createTempDirectory("file-transfer-publication")
            val objects = Files.createDirectories(root.resolve("objects"))
            Files.write(objects.resolve("${storageName(fileKey)}.bin"), "unpublished".encodeToByteArray())
            val endpoint = FileSystemFileTransferEndpoint(root)

            endpoint
                .read(fileKey, 0, 3)
                .shouldBeInstanceOf<FileTransferResult.Failure>()
                .error shouldBe FileTransferError.NotFound(fileKey)
        }
    }
}

private data class ContractFixture(
    val source: FileSystemFileTransferEndpoint,
    val subject: FileTransferEndpoint,
    val remote: FileSystemFileTransferEndpoint,
)

private fun localFixture(): ContractFixture {
    val root = Files.createTempDirectory("file-transfer-local")
    val source = FileSystemFileTransferEndpoint(root.resolve("source"))
    val remote = FileSystemFileTransferEndpoint(root.resolve("remote"))
    return ContractFixture(source, remote, remote)
}

private fun messagingFixture(): ContractFixture {
    val root = Files.createTempDirectory("file-transfer-messaging")
    val source = FileSystemFileTransferEndpoint(root.resolve("source"))
    val remote = FileSystemFileTransferEndpoint(root.resolve("remote"))
    val handler = FileTransferMessageHandler(remote)
    val channel = FileTransferMessageChannel { payload -> handler.handle(payload.copyOf()) }
    return ContractFixture(source, MessagingFileTransferEndpoint(channel), remote)
}

private class RecordingEndpoint(
    private val delegate: FileTransferEndpoint,
) : FileTransferEndpoint by delegate {
    val chunkSizes = mutableListOf<Int>()

    override suspend fun write(
        transferId: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): FileTransferResult<Long> {
        chunkSizes += bytes.size
        return delegate.write(transferId, offset, bytes)
    }
}

private class InvalidDigestEndpoint(
    private val delegate: FileTransferEndpoint,
) : FileTransferEndpoint by delegate {
    override suspend fun metadata(key: FileKey): FileTransferResult<FileMetadata> {
        val metadata = delegate.metadata(key).shouldSucceed()
        return FileTransferResult.Success(metadata.copy(digest = FileDigest.sha256("0".repeat(64))))
    }
}

private fun <Value> FileTransferResult<Value>.shouldSucceed(): Value =
    when (this) {
        is FileTransferResult.Success -> value
        is FileTransferResult.Failure -> error("Expected file transfer success but received $error")
    }

private val coordinator = FileTransferCoordinator(chunkSize = 3)
private val fileKey = FileKey(FileId.of("fixture"), FileRevision.of("1.0.0"))

private fun storageName(key: FileKey): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest("${key.id.value}\u0000${key.revision.value}".encodeToByteArray())
        .joinToString("") { "%02x".format(it) }
