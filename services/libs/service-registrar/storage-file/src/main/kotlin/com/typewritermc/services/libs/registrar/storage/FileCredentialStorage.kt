package com.typewritermc.services.libs.registrar.storage

import com.typewritermc.services.libs.registrar.CredentialLoadResult
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.CredentialStorageError
import com.typewritermc.services.libs.registrar.CredentialStoreResult
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.nio.file.attribute.PosixFilePermission

/** Versioned plaintext credential storage backed by one atomically replaced file. */
class FileCredentialStorage(
    private val path: Path,
    private val maximumBytes: Long = 64 * 1024,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
) : CredentialStorage {
    private val json =
        Json {
            encodeDefaults = true
            ignoreUnknownKeys = false
        }

    init {
        require(maximumBytes > 0) { "Maximum credential file size must be positive" }
    }

    override suspend fun load(): CredentialLoadResult =
        withContext(dispatcher) {
            if (!Files.exists(path)) return@withContext CredentialLoadResult.Missing
            if (Files.isSymbolicLink(path) || !Files.isRegularFile(path)) {
                return@withContext corrupt()
            }
            try {
                val size = Files.size(path)
                if (size > maximumBytes) return@withContext corrupt()
                val bytes = Files.readAllBytes(path)
                if (bytes.size.toLong() > maximumBytes) return@withContext corrupt()
                val record = json.decodeFromString<StoredCredential>(bytes.decodeToString())
                if (record.version != FORMAT_VERSION) {
                    return@withContext CredentialLoadResult.Failure(
                        CredentialStorageError.UnsupportedVersion(record.version),
                    )
                }
                CredentialLoadResult.Loaded(record.toCredentials())
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                when (failure) {
                    is SerializationException, is IllegalArgumentException -> corrupt()
                    else -> unavailable()
                }
            }
        }

    override suspend fun store(credentials: IdentityCredentials): CredentialStoreResult =
        withContext(dispatcher) {
            val encoded = json.encodeToString(StoredCredential.from(credentials)).encodeToByteArray()
            if (encoded.size.toLong() > maximumBytes) {
                return@withContext CredentialStoreResult.Failure(CredentialStorageError.Corrupt(STORAGE_LIMIT_SLUG))
            }
            val parent =
                path.toAbsolutePath().parent
                    ?: return@withContext CredentialStoreResult.Failure(CredentialStorageError.Unavailable(STORAGE_WRITE_SLUG))
            var temporary: Path? = null
            try {
                Files.createDirectories(parent)
                temporary = Files.createTempFile(parent, ".${path.fileName}.", ".tmp")
                FileChannel.open(temporary, StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING).use { channel ->
                    var remaining = ByteBuffer.wrap(encoded)
                    while (remaining.hasRemaining()) channel.write(remaining)
                    channel.force(true)
                }
                setOwnerOnlyPermissions(temporary)
                try {
                    Files.move(
                        temporary,
                        path,
                        StandardCopyOption.ATOMIC_MOVE,
                        StandardCopyOption.REPLACE_EXISTING,
                    )
                } catch (_: AtomicMoveNotSupportedException) {
                    Files.move(temporary, path, StandardCopyOption.REPLACE_EXISTING)
                }
                setOwnerOnlyPermissions(path)
                CredentialStoreResult.Success
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                CredentialStoreResult.Failure(CredentialStorageError.Unavailable(STORAGE_WRITE_SLUG))
            } finally {
                temporary?.let(::deleteTemporary)
            }
        }

    private fun setOwnerOnlyPermissions(target: Path) {
        try {
            Files.setPosixFilePermissions(
                target,
                setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE),
            )
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
        }
    }

    private fun deleteTemporary(temporary: Path) {
        try {
            Files.deleteIfExists(temporary)
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
        }
    }
}

@Serializable
private data class StoredCredential(
    val version: Int,
    val serviceId: String,
    val displayName: String,
    val username: String,
    val roles: List<StoredRole>,
    val token: String,
) {
    fun toCredentials(): IdentityCredentials =
        IdentityCredentials(
            ServiceIdentity(serviceId, displayName, username, roles.map(StoredRole::toRole)),
            RedactedSecret.AppPassword(token),
        )

    companion object {
        fun from(credentials: IdentityCredentials) =
            StoredCredential(
                FORMAT_VERSION,
                credentials.identity.serviceId,
                credentials.identity.displayName,
                credentials.identity.username,
                credentials.identity.roles.map(StoredRole::from),
                credentials.revealAppPassword(),
            )
    }
}

@Serializable
private data class StoredRole(
    val type: String,
    val version: String,
    val name: String? = null,
) {
    fun toRole(): ServiceRole =
        when (type) {
            "engine" -> ServiceRole.Engine(version)
            "realm" -> ServiceRole.Realm(version)
            "custom" -> ServiceRole.Custom(requireNotNull(name), version)
            else -> throw IllegalArgumentException("Unknown stored role type")
        }

    companion object {
        fun from(role: ServiceRole): StoredRole =
            when (role) {
                is ServiceRole.Engine -> StoredRole("engine", role.version)
                is ServiceRole.Realm -> StoredRole("realm", role.version)
                is ServiceRole.Custom -> StoredRole("custom", role.version, role.name)
            }
    }
}

private fun corrupt() = CredentialLoadResult.Failure(CredentialStorageError.Corrupt(STORAGE_CORRUPT_SLUG))

private fun unavailable() = CredentialLoadResult.Failure(CredentialStorageError.Unavailable(STORAGE_READ_SLUG))

private const val FORMAT_VERSION = 1
private const val STORAGE_CORRUPT_SLUG = "credential_file_corrupt"
private const val STORAGE_READ_SLUG = "credential_file_read_unavailable"
private const val STORAGE_WRITE_SLUG = "credential_file_write_unavailable"
private const val STORAGE_LIMIT_SLUG = "credential_file_too_large"
