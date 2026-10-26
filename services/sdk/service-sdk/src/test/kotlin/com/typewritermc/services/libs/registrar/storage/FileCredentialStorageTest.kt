package com.typewritermc.services.libs.registrar.storage

import com.typewritermc.services.libs.registrar.CredentialLoadResult
import com.typewritermc.services.libs.registrar.CredentialStorageError
import com.typewritermc.services.libs.registrar.CredentialStoreResult
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import java.nio.file.Files
import java.nio.file.Path

private fun credentials(id: String = "service-id") =
    IdentityCredentials(
        ServiceIdentity(
            ServiceId(id),
            "Service Name",
            "service-user",
            ServiceRole.Custom("custom_role", "7.8.9"),
        ),
        RedactedSecret.AppPassword("private-password"),
    )

/** A temporary credential directory whose [storage] runs on the test scheduler; deleted after the case. */
private class StorageFixture(
    val directory: Path,
    private val scope: TestScope,
) {
    val path: Path = directory.resolve("identity.cbor")

    fun storage(
        at: Path = path,
        maximumBytes: Long = 64 * 1024,
    ) = FileCredentialStorage(at, maximumBytes, StandardTestDispatcher(scope.testScheduler))

    suspend fun loadError(
        at: Path = path,
        maximumBytes: Long = 64 * 1024,
    ): CredentialStorageError = storage(at, maximumBytes).load().shouldBeInstanceOf<CredentialLoadResult.Failure>().error
}

private fun withStorage(block: suspend StorageFixture.() -> Unit) {
    val directory = Files.createTempDirectory("registrar-storage")
    try {
        runTest { StorageFixture(directory, this).block() }
    } finally {
        directory.toFile().deleteRecursively()
    }
}

private val CORRUPT = CredentialStorageError.Corrupt("credential_file_corrupt")

@OptIn(ExperimentalSerializationApi::class)
val FileCredentialStorageTest by testSuite {
    test("missing file returns Missing") {
        withStorage { storage().load() shouldBe CredentialLoadResult.Missing }
    }

    test("round trips every identity field and issued service role") {
        withStorage {
            storage().store(credentials()) shouldBe CredentialStoreResult.Success
            val loaded = storage().load().shouldBeInstanceOf<CredentialLoadResult.Loaded>().credentials
            loaded.identity.serviceId shouldBe ServiceId("service-id")
            loaded.identity.displayName shouldBe "Service Name"
            loaded.identity.username shouldBe "service-user"
            loaded.identity.role shouldBe ServiceRole.Custom("custom_role", "7.8.9")
            loaded.revealAppPassword() shouldBe "private-password"
        }
    }

    test("replaces an existing identity") {
        withStorage {
            storage().store(credentials("first")) shouldBe CredentialStoreResult.Success
            storage().store(credentials("second")) shouldBe CredentialStoreResult.Success
            storage()
                .load()
                .shouldBeInstanceOf<CredentialLoadResult.Loaded>()
                .credentials.identity.serviceId shouldBe
                ServiceId("second")
            Files.list(directory).use { it.count() } shouldBe 1L
        }
    }

    test("malformed file is corrupt") {
        withStorage {
            Files.writeString(path, "not-cbor")
            loadError() shouldBe CORRUPT
        }
    }

    test("unknown version is explicit") {
        withStorage {
            Files.write(
                path,
                Cbor.Default.encodeToByteArray(
                    StoredCredentialFixture.serializer(),
                    StoredCredentialFixture(
                        version = 3,
                        serviceId = "id",
                        displayName = "name",
                        username = "user",
                        issuedServiceRole = StoredServiceRoleFixture("host", "1.0.0"),
                        token = "token",
                    ),
                ),
            )
            loadError() shouldBe CredentialStorageError.UnsupportedVersion(3)
        }
    }

    test("a file over the size limit is corrupt") {
        withStorage {
            Files.write(path, ByteArray(33) { 1 })
            loadError(maximumBytes = 32) shouldBe CORRUPT
        }
    }

    test("a directory at the credential path is corrupt") {
        withStorage { loadError(at = directory) shouldBe CORRUPT }
    }

    test("a symbolic link to valid credentials is corrupt") {
        withStorage {
            val target = directory.resolve("elsewhere.cbor")
            storage(at = target).store(credentials()) shouldBe CredentialStoreResult.Success
            Files.createSymbolicLink(path, target)
            loadError() shouldBe CORRUPT
        }
    }
}

@Serializable
private data class StoredCredentialFixture(
    val version: Int,
    val serviceId: String,
    val displayName: String,
    val username: String,
    val issuedServiceRole: StoredServiceRoleFixture,
    val token: String,
)

@Serializable
private data class StoredServiceRoleFixture(
    val type: String,
    val version: String,
    val name: String? = null,
)
