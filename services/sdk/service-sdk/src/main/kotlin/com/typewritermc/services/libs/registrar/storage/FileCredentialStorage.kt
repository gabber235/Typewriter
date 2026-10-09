package com.typewritermc.services.libs.registrar.storage

import com.typewritermc.services.libs.registrar.CredentialLoadResult
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.CredentialStorageError
import com.typewritermc.services.libs.registrar.CredentialStoreResult
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.utils.rethrowExceptional
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.cbor.Cbor
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.nio.file.attribute.PosixFilePermission

/**
 * Persists versioned plaintext credentials using a bounded CBOR file and replacement writes.
 *
 * Missing, corrupt, unsupported, and unavailable storage remain distinct. Reads reject symlinks and oversized
 * files. Writes flush temporary bytes and attempt owner only permissions; unsupported permission operations are
 * tolerated. Atomic moves are used when available, with ordinary replacement as fallback.
 */
@OptIn(ExperimentalSerializationApi::class)
class FileCredentialStorage(
    private val path: Path,
    private val maximumBytes: Long = 64 * 1024,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
) : CredentialStorage {
    private val cbor = Cbor { encodeDefaults = true }

    init {
        require(maximumBytes > 0) { "Maximum credential file size must be positive" }
    }

    override suspend fun load(): CredentialLoadResult =
        withContext(dispatcher) {
            if (!Files.exists(path)) return@withContext CredentialLoadResult.Missing
            if (Files.isSymbolicLink(path) || !Files.isRegularFile(path)) return@withContext corrupt()
            try {
                val size = Files.size(path)
                if (size > maximumBytes) return@withContext corrupt()
                val bytes = Files.readAllBytes(path)
                if (bytes.size.toLong() > maximumBytes) return@withContext corrupt()
                val record = cbor.decodeFromByteArray(StoredCredential.serializer(), bytes)
                if (record.version != FORMAT_VERSION) {
                    return@withContext CredentialLoadResult.Failure(
                        CredentialStorageError.UnsupportedVersion(record.version),
                    )
                }
                CredentialLoadResult.Loaded(record.toCredentials())
            } catch (failure: Throwable) {
                failure.rethrowExceptional()
                when (failure) {
                    is SerializationException, is IllegalArgumentException -> corrupt()
                    else -> unavailable()
                }
            }
        }

    override suspend fun store(credentials: IdentityCredentials): CredentialStoreResult =
        withContext(dispatcher) {
            val encoded = cbor.encodeToByteArray(StoredCredential.serializer(), StoredCredential.from(credentials))
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
                    val remaining = ByteBuffer.wrap(encoded)
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
                failure.rethrowExceptional()
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
            failure.rethrowExceptional()
        }
    }

    private fun deleteTemporary(temporary: Path) {
        try {
            Files.deleteIfExists(temporary)
        } catch (failure: Throwable) {
            failure.rethrowExceptional()
        }
    }
}

@Serializable
private data class StoredCredential(
    val version: Int,
    val serviceId: String,
    val displayName: String,
    val username: String,
    val issuedServiceRole: StoredServiceRole,
    val token: String,
) {
    fun toCredentials(): IdentityCredentials =
        IdentityCredentials(
            ServiceIdentity(ServiceId(serviceId), displayName, username, issuedServiceRole.toRole()),
            RedactedSecret.AppPassword(token),
        )

    companion object {
        fun from(credentials: IdentityCredentials) =
            StoredCredential(
                FORMAT_VERSION,
                credentials.identity.serviceId.value,
                credentials.identity.displayName,
                credentials.identity.username,
                StoredServiceRole.from(credentials.identity.role),
                credentials.revealAppPassword(),
            )
    }
}

@Serializable
private data class StoredServiceRole(
    val type: String,
    val version: String,
    val name: String? = null,
) {
    fun toRole(): ServiceRole =
        when (type) {
            "host" -> ServiceRole.Host(version)
            "custom" -> ServiceRole.Custom(requireNotNull(name), version)
            else -> throw IllegalArgumentException("Unknown stored role type")
        }

    companion object {
        fun from(role: ServiceRole): StoredServiceRole =
            when (role) {
                is ServiceRole.Host -> StoredServiceRole("host", role.version)
                is ServiceRole.Custom -> StoredServiceRole("custom", role.version, role.name)
            }
    }
}

private fun corrupt() = CredentialLoadResult.Failure(CredentialStorageError.Corrupt(STORAGE_CORRUPT_SLUG))

private fun unavailable() = CredentialLoadResult.Failure(CredentialStorageError.Unavailable(STORAGE_READ_SLUG))

private const val FORMAT_VERSION = 2
private const val STORAGE_CORRUPT_SLUG = "credential_file_corrupt"
private const val STORAGE_READ_SLUG = "credential_file_read_unavailable"
private const val STORAGE_WRITE_SLUG = "credential_file_write_unavailable"
private const val STORAGE_LIMIT_SLUG = "credential_file_too_large"
