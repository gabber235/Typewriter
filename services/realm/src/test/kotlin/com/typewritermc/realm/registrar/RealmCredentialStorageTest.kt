package com.typewritermc.realm.registrar

import com.typewritermc.services.libs.registrar.CredentialLoadResult
import com.typewritermc.services.libs.registrar.CredentialStorageError
import com.typewritermc.services.libs.registrar.CredentialStoreResult
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import java.io.File
import java.nio.file.Files

private fun credentials(id: String = "service-id") = IdentityCredentials(
    ServiceIdentity(
        id,
        "Realm Service",
        "realm-user",
        listOf(
            ServiceRole.Engine("1.2.3"),
            ServiceRole.Realm("4.5.6"),
            ServiceRole.Custom("custom_role", "7.8.9"),
        ),
    ),
    RedactedSecret.AppPassword("private-password"),
)

@Serializable
private data class TestStoredCredential(
    val version: Int,
    val serviceId: String,
    val displayName: String,
    val username: String,
    val token: String,
)

@OptIn(ExperimentalSerializationApi::class)
class RealmCredentialStorageTest : FunSpec({
    lateinit var temporaryDirectory: File
    lateinit var credentialFile: File
    val cbor = Cbor { }

    beforeTest {
        temporaryDirectory = Files.createTempDirectory("realm-credential-test").toFile()
        credentialFile = File(temporaryDirectory, "credentials.cbor")
    }

    afterTest { (_, _) -> temporaryDirectory.deleteRecursively() }

    test("missing file returns Missing") {
        runTest {
            storage(cbor, credentialFile).load() shouldBe CredentialLoadResult.Missing
        }
    }

    test("round trips stored identity fields and supplies the runtime role") {
        runTest {
            val runtimeRole = ServiceRole.Realm("9.8.7")
            val storage = storage(cbor, credentialFile, runtimeRole)
            storage.store(credentials()) shouldBe CredentialStoreResult.Success

            val loaded = storage.load() as CredentialLoadResult.Loaded
            loaded.credentials.identity.serviceId shouldBe "service-id"
            loaded.credentials.identity.displayName shouldBe "Realm Service"
            loaded.credentials.identity.username shouldBe "realm-user"
            loaded.credentials.identity.roles.shouldContainExactly(
                runtimeRole,
            )
            loaded.credentials.revealAppPassword() shouldBe "private-password"
        }
    }

    test("stored record excludes roles") {
        runTest {
            storage(cbor, credentialFile).store(credentials()) shouldBe CredentialStoreResult.Success

            val record = cbor.decodeFromByteArray<TestStoredCredential>(credentialFile.readBytes())
            record shouldBe TestStoredCredential(
                version = 1,
                serviceId = "service-id",
                displayName = "Realm Service",
                username = "realm-user",
                token = "private-password",
            )
        }
    }

    test("store replaces an existing identity") {
        runTest {
            val storage = storage(cbor, credentialFile)
            storage.store(credentials("first")) shouldBe CredentialStoreResult.Success
            storage.store(credentials("second")) shouldBe CredentialStoreResult.Success

            val loaded = storage.load() as CredentialLoadResult.Loaded
            loaded.credentials.identity.serviceId shouldBe "second"
            Files.list(temporaryDirectory.toPath()).use { it.count() } shouldBe 1L
        }
    }

    test("malformed file returns corrupt failure") {
        credentialFile.writeBytes(byteArrayOf(0x00, 0xFF.toByte(), 0x01, 0x02))

        runTest {
            val result = storage(cbor, credentialFile).load() as CredentialLoadResult.Failure
            (result.error is CredentialStorageError.Corrupt) shouldBe true
        }
    }

    test("unknown version returns explicit failure") {
        val record = TestStoredCredential(
            version = 2,
            serviceId = "service-id",
            displayName = "Realm Service",
            username = "realm-user",
            token = "private-password",
        )
        credentialFile.writeBytes(cbor.encodeToByteArray(record))

        runTest {
            val result = storage(cbor, credentialFile).load() as CredentialLoadResult.Failure
            result.error shouldBe CredentialStorageError.UnsupportedVersion(2)
        }
    }

    test("oversized file returns corrupt failure without reading it") {
        credentialFile.writeBytes(ByteArray(33) { 1 })

        runTest {
            val result = storage(cbor, credentialFile, maximumBytes = 32).load() as CredentialLoadResult.Failure
            (result.error is CredentialStorageError.Corrupt) shouldBe true
        }
    }

    test("store creates missing parent directories") {
        val nestedFile = File(temporaryDirectory, "nested/deep/credentials.cbor")

        runTest {
            storage(cbor, nestedFile).store(credentials()) shouldBe CredentialStoreResult.Success
            nestedFile.exists() shouldBe true
        }
    }

    test("credential diagnostics remain redacted") {
        credentials().toString().contains("private-password") shouldBe false
    }
})

private fun TestScope.storage(
    cbor: Cbor,
    file: File,
    role: ServiceRole = ServiceRole.Realm("1.0.0"),
    maximumBytes: Long = 64 * 1024,
): RealmCredentialStorage = RealmCredentialStorage(
    cbor,
    file,
    role,
    maximumBytes,
    StandardTestDispatcher(testScheduler),
)
