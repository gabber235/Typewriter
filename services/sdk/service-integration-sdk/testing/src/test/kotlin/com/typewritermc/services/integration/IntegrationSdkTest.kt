package com.typewritermc.services.integration

import com.typewritermc.services.integration.client.GeneratedIntegrationClient
import com.typewritermc.services.integration.client.IntegrationRegistry
import com.typewritermc.services.integration.client.RegistrationResult
import com.typewritermc.services.integration.messaging.AuthenticatedIntegrationMessage
import com.typewritermc.services.integration.messaging.AuthenticatedIntegrationMessageHandler
import com.typewritermc.services.integration.messaging.IntegrationAuthenticator
import com.typewritermc.services.integration.messaging.IntegrationDispatcher
import com.typewritermc.services.integration.messaging.MessagingIntegrationGateway
import com.typewritermc.services.libs.filetransfer.FileChunk
import com.typewritermc.services.libs.filetransfer.FileKey
import com.typewritermc.services.libs.filetransfer.FileMetadata
import com.typewritermc.services.libs.filetransfer.FileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.FileTransferError
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.FileWriteSession
import com.typewritermc.services.libs.filetransfer.TransferId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.runTest

val IntegrationSdkTest by testSuite {
    test("integrations register and unregister independently") {
        val registry = IntegrationRegistry()
        val first = registration("first")
        val second = registration("second")

        val firstLease = registry.register(first).shouldBeInstanceOf<RegistrationResult.Registered>().lease
        registry.register(second).shouldBeInstanceOf<RegistrationResult.Registered>()
        registry.register(first) shouldBe RegistrationResult.Duplicate(first.id)
        registry.registrations() shouldContainExactly listOf(first, second)

        registry.unregister(firstLease) shouldBe true
        registry.registrations() shouldContainExactly listOf(second)
    }

    test("generated clients reject missing permissions before transport") {
        runTest {
            val gateway = RecordingGateway()
            val operation = command(IntegrationPermission.EXECUTE)
            val client = client(registration("reader", IntegrationPermission.REALM_READ), gateway, operation)

            client.call(operation, "request") shouldBe IntegrationResult.PermissionDenied(IntegrationPermission.EXECUTE)
            gateway.requests shouldBe 0
        }
    }

    test("file transfer access is permission checked before the endpoint") {
        runTest {
            val endpoint = RecordingFileTransferEndpoint()
            val operation = command(IntegrationPermission.REALM_READ)
            val client = client(registration("reader", IntegrationPermission.REALM_READ), RecordingGateway(), operation, endpoint)

            val result = client.files.metadata(fileKey)
            result shouldBe IntegrationResult.PermissionDenied(IntegrationPermission.FILE_TRANSFER)
            endpoint.calls shouldBe 0
        }
    }

    test("authenticated messaging enforces server side permissions") {
        runTest {
            val operation = command(IntegrationPermission.ADMINISTER)
            val registration = registration("limited", IntegrationPermission.REALM_READ)
            val dispatcher = RecordingDispatcher()
            val handler =
                AuthenticatedIntegrationMessageHandler(
                    GeneratedIntegrationContract(listOf(operation), emptyList()),
                    IntegrationAuthenticator { registration },
                    dispatcher,
                )
            val gateway = MessagingIntegrationGateway(handler)
            val context = IntegrationContext(registration.id, registration.realmId, credential)

            gateway.request(context, operation.kind, operation.id, byteArrayOf()) shouldBe
                IntegrationResult.PermissionDenied(IntegrationPermission.ADMINISTER)
            dispatcher.requests shouldBe 0
        }
    }

    test("authenticated messaging dispatches a valid generated command") {
        runTest {
            val operation = command(IntegrationPermission.EXECUTE)
            val registration = registration("executor", IntegrationPermission.EXECUTE)
            val dispatcher = RecordingDispatcher(response = textCodec.encode("response"))
            val handler =
                AuthenticatedIntegrationMessageHandler(
                    GeneratedIntegrationContract(listOf(operation), emptyList()),
                    IntegrationAuthenticator { context ->
                        registration.takeIf { context.credential == credential }
                    },
                    dispatcher,
                )
            val client = client(registration, MessagingIntegrationGateway(handler), operation)

            client.call(operation, "request") shouldBe IntegrationResult.Success("response")
            dispatcher.requests shouldBe 1
        }
    }

    test("generated contracts reject duplicate operation ids") {
        val operation = command(IntegrationPermission.EXECUTE)
        shouldThrow<IllegalArgumentException> {
            GeneratedIntegrationContract(listOf(operation, operation), emptyList())
        }
    }
}

private val credential = IntegrationCredential.of("credential")
private val realmId = IntegrationRealmId.of("realm")
private val fileKey =
    FileKey(
        com.typewritermc.services.libs.filetransfer.FileId
            .of("file"),
        com.typewritermc.services.libs.filetransfer.FileRevision
            .of("1"),
    )

private val textCodec =
    object : IntegrationCodec<String> {
        override fun encode(value: String): ByteArray = value.encodeToByteArray()

        override fun decode(bytes: ByteArray): String = bytes.decodeToString()
    }

private fun registration(
    id: String,
    vararg permissions: IntegrationPermission,
) = IntegrationRegistration(IntegrationId.of(id), realmId, permissions.toSet())

private fun command(permission: IntegrationPermission) =
    IntegrationOperation(
        id = IntegrationOperationId.of("command"),
        kind = IntegrationOperationKind.COMMAND,
        permission = permission,
        requestCodec = textCodec,
        responseCodec = textCodec,
    )

private fun client(
    registration: IntegrationRegistration,
    gateway: IntegrationGateway,
    operation: IntegrationOperation<String, String>,
    endpoint: FileTransferEndpoint = RecordingFileTransferEndpoint(),
) = GeneratedIntegrationClient(
    registration,
    credential,
    GeneratedIntegrationContract(listOf(operation), emptyList()),
    gateway,
    endpoint,
)

private class RecordingGateway : IntegrationGateway {
    var requests = 0

    override suspend fun request(
        context: IntegrationContext,
        kind: IntegrationOperationKind,
        operationId: IntegrationOperationId,
        payload: ByteArray,
    ): IntegrationResult<ByteArray> {
        requests++
        return IntegrationResult.Success(payload)
    }

    override suspend fun publish(
        context: IntegrationContext,
        eventId: IntegrationOperationId,
        payload: ByteArray,
    ): IntegrationResult<Unit> = IntegrationResult.Success(Unit)

    override fun events(
        context: IntegrationContext,
        eventId: IntegrationOperationId,
    ): Flow<IntegrationResult<ByteArray>> = emptyFlow()
}

private class RecordingDispatcher(
    private val response: ByteArray = byteArrayOf(),
) : IntegrationDispatcher {
    var requests = 0

    override suspend fun request(
        registration: IntegrationRegistration,
        message: AuthenticatedIntegrationMessage,
    ): IntegrationResult<ByteArray> {
        requests++
        return IntegrationResult.Success(response)
    }

    override suspend fun publish(
        registration: IntegrationRegistration,
        message: AuthenticatedIntegrationMessage,
    ): IntegrationResult<Unit> = IntegrationResult.Success(Unit)

    override fun events(
        registration: IntegrationRegistration,
        message: AuthenticatedIntegrationMessage,
    ): Flow<IntegrationResult<ByteArray>> = emptyFlow()
}

private class RecordingFileTransferEndpoint : FileTransferEndpoint {
    var calls = 0

    override suspend fun metadata(key: FileKey): FileTransferResult<FileMetadata> {
        calls++
        return FileTransferResult.Failure(FileTransferError.NotFound(key))
    }

    override suspend fun read(
        key: FileKey,
        offset: Long,
        maximumBytes: Int,
    ): FileTransferResult<FileChunk> = error("Not used")

    override suspend fun beginWrite(
        transferId: TransferId,
        metadata: FileMetadata,
    ): FileTransferResult<FileWriteSession> = error("Not used")

    override suspend fun write(
        transferId: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): FileTransferResult<Long> = error("Not used")

    override suspend fun complete(transferId: TransferId): FileTransferResult<FileMetadata> = error("Not used")

    override suspend fun cancel(transferId: TransferId): FileTransferResult<Unit> = error("Not used")
}
