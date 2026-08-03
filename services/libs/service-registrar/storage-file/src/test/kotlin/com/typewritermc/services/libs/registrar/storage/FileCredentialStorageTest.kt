package com.typewritermc.services.libs.registrar.storage

import com.typewritermc.services.libs.registrar.CredentialLoadResult
import com.typewritermc.services.libs.registrar.CredentialStorageError
import com.typewritermc.services.libs.registrar.CredentialStoreResult
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import java.nio.file.Files

private fun credentials(id: String = "service-id") =
    IdentityCredentials(
        ServiceIdentity(
            id,
            "Service Name",
            "service-user",
            listOf(
                ServiceRole.Engine("1.2.3"),
                ServiceRole.Realm("4.5.6"),
                ServiceRole.Custom("custom_role", "7.8.9"),
            ),
        ),
        RedactedSecret.AppPassword("private-password"),
    )

val FileCredentialStorageTest by testSuite {
    test("missing file returns Missing") {
        val directory = Files.createTempDirectory("registrar-storage")
        try {
            runTest {
                FileCredentialStorage(directory.resolve("identity.json"), dispatcher = StandardTestDispatcher(testScheduler))
                    .load() shouldBe CredentialLoadResult.Missing
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }

    test("round trips every identity field and role") {
        val directory = Files.createTempDirectory("registrar-storage")
        try {
            runTest {
                val storage =
                    FileCredentialStorage(
                        directory.resolve("identity.json"),
                        dispatcher = StandardTestDispatcher(testScheduler),
                    )
                storage.store(credentials()) shouldBe CredentialStoreResult.Success
                val loaded = storage.load() as CredentialLoadResult.Loaded
                loaded.credentials.identity.serviceId shouldBe "service-id"
                loaded.credentials.identity.displayName shouldBe "Service Name"
                loaded.credentials.identity.username shouldBe "service-user"
                loaded.credentials.identity.roles.shouldContainExactly(
                    ServiceRole.Engine("1.2.3"),
                    ServiceRole.Realm("4.5.6"),
                    ServiceRole.Custom("custom_role", "7.8.9"),
                )
                loaded.credentials.revealAppPassword() shouldBe "private-password"
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }

    test("replaces an existing identity") {
        val directory = Files.createTempDirectory("registrar-storage")
        try {
            runTest {
                val storage =
                    FileCredentialStorage(
                        directory.resolve("identity.json"),
                        dispatcher = StandardTestDispatcher(testScheduler),
                    )
                storage.store(credentials("first")) shouldBe CredentialStoreResult.Success
                storage.store(credentials("second")) shouldBe CredentialStoreResult.Success
                val loaded = storage.load() as CredentialLoadResult.Loaded
                loaded.credentials.identity.serviceId shouldBe "second"
                Files.list(directory).use { it.count() } shouldBe 1L
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }

    test("malformed file is corrupt") {
        val directory = Files.createTempDirectory("registrar-storage")
        try {
            val path = directory.resolve("identity.json")
            Files.writeString(path, "not-json")
            runTest {
                val result = FileCredentialStorage(path, dispatcher = StandardTestDispatcher(testScheduler)).load()
                ((result as CredentialLoadResult.Failure).error is CredentialStorageError.Corrupt) shouldBe true
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }

    test("unknown version is explicit") {
        val directory = Files.createTempDirectory("registrar-storage")
        try {
            val path = directory.resolve("identity.json")
            Files.writeString(
                path,
                """{"version":2,"serviceId":"id","displayName":"name","username":"user","roles":[],"token":"token"}""",
            )
            runTest {
                val result = FileCredentialStorage(path, dispatcher = StandardTestDispatcher(testScheduler)).load()
                (result as CredentialLoadResult.Failure).error shouldBe CredentialStorageError.UnsupportedVersion(2)
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }

    test("oversized file is corrupt without reading it") {
        val directory = Files.createTempDirectory("registrar-storage")
        try {
            val path = directory.resolve("identity.json")
            Files.write(path, ByteArray(33) { 1 })
            runTest {
                val result =
                    FileCredentialStorage(
                        path,
                        maximumBytes = 32,
                        dispatcher = StandardTestDispatcher(testScheduler),
                    ).load()
                ((result as CredentialLoadResult.Failure).error is CredentialStorageError.Corrupt) shouldBe true
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }

    test("directories and symbolic links are corrupt inputs") {
        val directory = Files.createTempDirectory("registrar-storage")
        try {
            runTest {
                val result = FileCredentialStorage(directory, dispatcher = StandardTestDispatcher(testScheduler)).load()
                ((result as CredentialLoadResult.Failure).error is CredentialStorageError.Corrupt) shouldBe true
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }

    test("credentials and stored diagnostics remain redacted") {
        val value = credentials()
        value.toString().contains("private-password") shouldBe false
    }
}
