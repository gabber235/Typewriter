package com.typewritermc.realm.registrar

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
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import java.io.File
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.nio.file.attribute.PosixFilePermission

@OptIn(ExperimentalSerializationApi::class)
class RealmCredentialStorage(
    private val cbor: Cbor,
    file: File,
    private val role: ServiceRole,
    private val maximumBytes: Long = 64 * 1024,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
) : CredentialStorage {
    private val path = file.toPath()

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
                val record = cbor.decodeFromByteArray<StoredCredential>(bytes)
                if (record.formatVersion != FORMAT_VERSION) {
                    return@withContext CredentialLoadResult.Failure(
                        CredentialStorageError.UnsupportedVersion(record.formatVersion),
                    )
                }
                CredentialLoadResult.Loaded(record.toCredentials(role))
            } catch (failure: Throwable) {
                rethrowExceptionalThrowable(failure)
                when (failure) {
                    is SerializationException, is IllegalArgumentException -> corrupt()
                    else -> loadUnavailable()
                }
            }
        }

    override suspend fun store(credentials: IdentityCredentials): CredentialStoreResult =
        withContext(dispatcher) {
            val encoded = cbor.encodeToByteArray(StoredCredential.from(credentials))
            if (encoded.size.toLong() > maximumBytes) {
                return@withContext CredentialStoreResult.Failure(
                    CredentialStorageError.Corrupt(STORAGE_LIMIT_SLUG),
                )
            }
            val parent =
                path.toAbsolutePath().parent
                    ?: return@withContext storeUnavailable()
            var temporary: java.nio.file.Path? = null

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
                rethrowExceptionalThrowable(failure)
                storeUnavailable()
            } finally {
                temporary?.let(::deleteTemporary)
            }
        }

    private fun setOwnerOnlyPermissions(target: java.nio.file.Path) {
        try {
            Files.setPosixFilePermissions(
                target,
                setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE),
            )
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
        }
    }

    private fun deleteTemporary(temporary: java.nio.file.Path) {
        try {
            Files.deleteIfExists(temporary)
        } catch (failure: Throwable) {
            rethrowExceptionalThrowable(failure)
        }
    }
}

@Serializable
private data class StoredCredential(
    val formatVersion: Int,
    val serviceId: String,
    val displayName: String,
    val username: String,
    val token: String,
) {
    fun toCredentials(role: ServiceRole): IdentityCredentials =
        IdentityCredentials(
            ServiceIdentity(serviceId, displayName, username, listOf(role)),
            RedactedSecret.AppPassword(token),
        )

    companion object {
        fun from(credentials: IdentityCredentials) =
            StoredCredential(
                FORMAT_VERSION,
                credentials.identity.serviceId,
                credentials.identity.displayName,
                credentials.identity.username,
                credentials.revealAppPassword(),
            )
    }
}

private fun corrupt() = CredentialLoadResult.Failure(CredentialStorageError.Corrupt(STORAGE_CORRUPT_SLUG))

private fun loadUnavailable() = CredentialLoadResult.Failure(CredentialStorageError.Unavailable(STORAGE_READ_SLUG))

private fun storeUnavailable() = CredentialStoreResult.Failure(CredentialStorageError.Unavailable(STORAGE_WRITE_SLUG))

private const val FORMAT_VERSION = 1
private const val STORAGE_CORRUPT_SLUG = "realm_credential_file_corrupt"
private const val STORAGE_READ_SLUG = "realm_credential_file_read_unavailable"
private const val STORAGE_WRITE_SLUG = "realm_credential_file_write_unavailable"
private const val STORAGE_LIMIT_SLUG = "realm_credential_file_too_large"
