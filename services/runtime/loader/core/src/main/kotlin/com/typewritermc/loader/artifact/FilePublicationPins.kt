package com.typewritermc.loader.artifact

import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.utils.findExceptional
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.cbor.Cbor
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.NoSuchFileException
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption

// Core owned storage representation, not part of loader API.
@Serializable
internal data class RealmPublicationPins(
    val selected: String?,
    val publications: Map<String, Set<ArtifactDigest>>,
) {
    init {
        require(selected == null || selected in publications) {
            "Selected publication is absent from retention roots"
        }
    }

    val digests: Set<ArtifactDigest>
        get() = publications.values.flatten().toSet()
}

// Called only while FileDigestBlobStore.publicationGate is held.
@OptIn(ExperimentalSerializationApi::class)
internal class FilePublicationPins(
    private val file: Path,
) {
    private val codec = Cbor { encodeDefaults = true }
    private val serializer = MapSerializer(String.serializer(), RealmPublicationPins.serializer())

    suspend fun read(): Map<String, RealmPublicationPins> =
        withContext(Dispatchers.IO) {
            val bytes =
                try {
                    Files.readAllBytes(file)
                } catch (_: NoSuchFileException) {
                    return@withContext emptyMap()
                }
            codec.decodeFromByteArray(serializer, bytes)
        }

    suspend fun write(value: Map<String, RealmPublicationPins>) =
        withContext(Dispatchers.IO) {
            Files.createDirectories(file.parent)
            val temporary = Files.createTempFile(file.parent, "publication-pins", ".tmp")
            var failure: Throwable? = null
            try {
                val bytes = ByteBuffer.wrap(codec.encodeToByteArray(serializer, value))
                FileChannel.open(temporary, StandardOpenOption.WRITE).use { channel ->
                    while (bytes.hasRemaining()) channel.write(bytes)
                    channel.force(true)
                }
                Files.move(
                    temporary,
                    file,
                    StandardCopyOption.ATOMIC_MOVE,
                    StandardCopyOption.REPLACE_EXISTING,
                )
            } catch (caught: Throwable) {
                failure = caught
                throw caught
            } finally {
                try {
                    Files.deleteIfExists(temporary)
                } catch (cleanup: Throwable) {
                    val exceptional = cleanup.findExceptional()
                    if (exceptional != null) {
                        failure?.takeIf { it !== exceptional }?.let(exceptional::addSuppressed)
                        throw exceptional
                    }
                    if (failure != null) failure.addSuppressed(cleanup) else throw cleanup
                }
            }
        }
}
