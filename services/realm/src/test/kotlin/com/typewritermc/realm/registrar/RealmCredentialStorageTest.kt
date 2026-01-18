package com.typewritermc.realm.registrar

import com.typewritermc.services.libs.registrar.Credential
import io.kotest.core.spec.style.FunSpec
import io.kotest.core.test.TestCase
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import java.io.File
import java.nio.file.Files

@OptIn(ExperimentalSerializationApi::class)
class RealmCredentialStorageTest : FunSpec({

    lateinit var tempDir: File
    lateinit var credentialFile: File
    val cbor = Cbor { }

    beforeTest {
        tempDir = Files.createTempDirectory("realm-credential-test").toFile()
        credentialFile = File(tempDir, "credentials.cbor")
    }

    afterTest { (_, _) ->
        tempDir.deleteRecursively()
    }

    context("Happy Path Scenarios") {

        test("credential returns stored credential when file exists") {
            val originalCredential = Credential(id = "svc-123", name = "service-user", token = "secret")
            val bytes = cbor.encodeToByteArray(originalCredential)
            credentialFile.writeBytes(bytes)

            val storage = RealmCredentialStorage(cbor, credentialFile)
            val result = storage.credential()

            result shouldBe originalCredential
        }

        test("storeCredential persists credential to file") {
            val storage = RealmCredentialStorage(cbor, credentialFile)
            val credential = Credential(id = "new-svc", name = "new-user", token = "new-token")

            storage.storeCredential(credential)

            credentialFile.exists() shouldBe true
            val readCredential = cbor.decodeFromByteArray<Credential>(credentialFile.readBytes())
            readCredential shouldBe credential
        }

        test("storeCredential overwrites existing credential") {
            val oldCredential = Credential(id = "old", name = "old", token = "old")
            val newCredential = Credential(id = "new", name = "new", token = "new")
            credentialFile.writeBytes(cbor.encodeToByteArray(oldCredential))

            val storage = RealmCredentialStorage(cbor, credentialFile)
            storage.storeCredential(newCredential)

            val result = storage.credential()
            result shouldBe newCredential
        }

        test("stored credential can be read back correctly") {
            val storage = RealmCredentialStorage(cbor, credentialFile)
            val credential = Credential(
                id = "round-trip-svc",
                name = "round-trip-user",
                token = "round-trip-token"
            )

            storage.storeCredential(credential)
            val result = storage.credential()

            result shouldBe credential
        }
    }

    context("Error and Failure Scenarios") {

        test("credential returns null when file does not exist") {
            val storage = RealmCredentialStorage(cbor, credentialFile)

            val result = storage.credential()

            result.shouldBeNull()
        }

        test("credential returns null for empty file") {
            credentialFile.createNewFile()

            val storage = RealmCredentialStorage(cbor, credentialFile)

            runCatching { storage.credential() }.isFailure shouldBe true
        }

        test("credential throws on corrupted file") {
            credentialFile.writeBytes(byteArrayOf(0x00, 0xFF.toByte(), 0x01, 0x02))

            val storage = RealmCredentialStorage(cbor, credentialFile)

            runCatching { storage.credential() }.isFailure shouldBe true
        }
    }

    context("Edge Cases") {

        test("credential handles unicode characters in values") {
            val credential = Credential(
                id = "svc-日本語",
                name = "user@domain.com",
                token = "tök€n™"
            )
            credentialFile.writeBytes(cbor.encodeToByteArray(credential))

            val storage = RealmCredentialStorage(cbor, credentialFile)
            val result = storage.credential()

            result shouldBe credential
        }

        test("storeCredential creates parent directory if missing") {
            val nestedFile = File(tempDir, "nested/deep/credentials.cbor")
            nestedFile.parentFile.mkdirs()

            val storage = RealmCredentialStorage(cbor, nestedFile)
            val credential = Credential(id = "svc", name = "user", token = "token")

            storage.storeCredential(credential)

            nestedFile.exists() shouldBe true
        }

        test("credential handles very long token values") {
            val longToken = "T".repeat(10000)
            val credential = Credential(id = "svc", name = "user", token = longToken)
            credentialFile.writeBytes(cbor.encodeToByteArray(credential))

            val storage = RealmCredentialStorage(cbor, credentialFile)
            val result = storage.credential()

            result?.token shouldBe longToken
        }
    }
})
