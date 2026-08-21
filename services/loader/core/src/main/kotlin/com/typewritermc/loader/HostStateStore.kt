package com.typewritermc.loader

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

fun interface HostStateReader {
    fun load(): DesiredTopology?
}

fun interface HostStateWriter {
    fun save(topology: DesiredTopology)
}

interface HostStateStore :
    HostStateReader,
    HostStateWriter

@OptIn(ExperimentalSerializationApi::class)
class FileHostStateStore(
    private val path: Path,
) : HostStateStore {
    override fun load(): DesiredTopology? {
        if (!Files.exists(path)) return null
        val stored = cbor.decodeFromByteArray<StoredHostState>(Files.readAllBytes(path))
        require(stored.format == FORMAT_VERSION) { "Unsupported host state format: ${stored.format}" }
        return stored.topology
    }

    override fun save(topology: DesiredTopology) {
        Files.createDirectories(path.parent)
        val temporary = path.resolveSibling("${path.fileName}.tmp")
        Files.write(temporary, cbor.encodeToByteArray(StoredHostState(topology = topology)))
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
    }

    private companion object {
        const val FORMAT_VERSION = 1

        val cbor =
            Cbor {
                encodeDefaults = true
                ignoreUnknownKeys = true
            }
    }
}

@Serializable
internal data class StoredHostState(
    val format: Int = 1,
    val topology: DesiredTopology,
)
