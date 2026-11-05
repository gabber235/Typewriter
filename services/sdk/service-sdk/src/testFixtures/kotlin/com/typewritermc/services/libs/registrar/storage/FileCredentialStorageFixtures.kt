package com.typewritermc.services.libs.registrar.storage

import com.typewritermc.services.libs.registrar.CredentialLoadResult
import com.typewritermc.services.libs.registrar.CredentialStorageError
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.Serializable
import java.nio.file.Files
import java.nio.file.Path

fun credentials(id: String = "service-id") =
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
class StorageFixture(
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
    ): CredentialStorageError = storage(at, maximumBytes).load().let { (it as CredentialLoadResult.Failure).error }
}

fun withStorage(block: suspend StorageFixture.() -> Unit) {
    val directory = Files.createTempDirectory("registrar-storage")
    try {
        runTest { StorageFixture(directory, this).block() }
    } finally {
        directory.toFile().deleteRecursively()
    }
}

@Serializable
data class StoredCredentialFixture(
    val version: Int,
    val serviceId: String,
    val displayName: String,
    val username: String,
    val issuedServiceRole: StoredServiceRoleFixture,
    val token: String,
)

@Serializable
data class StoredServiceRoleFixture(
    val type: String,
    val version: String,
    val name: String? = null,
)
