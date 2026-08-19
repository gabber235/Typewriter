package com.typewritermc.loader

import java.io.DataInputStream
import java.io.DataOutputStream
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

class FileHostStateStore(
    private val path: Path,
) : HostStateStore {
    override fun load(): DesiredTopology? {
        if (!Files.exists(path)) return null
        return DataInputStream(Files.newInputStream(path)).use { input ->
            val format = input.readInt()
            require(format == FORMAT_VERSION) { "Unsupported host state format: $format" }
            DesiredTopology(
                revision = input.readLong(),
                realm = input.readChild(ChildKind.REALM),
                engine = input.readChild(ChildKind.ENGINE),
            )
        }
    }

    override fun save(topology: DesiredTopology) {
        Files.createDirectories(path.parent)
        val temporary = path.resolveSibling("${path.fileName}.tmp")
        DataOutputStream(Files.newOutputStream(temporary)).use { output ->
            output.writeInt(FORMAT_VERSION)
            output.writeLong(topology.revision)
            output.writeChild(topology.realm)
            output.writeChild(topology.engine)
        }
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

    private fun DataInputStream.readChild(kind: ChildKind): DesiredChild? {
        if (!readBoolean()) return null
        return DesiredChild(kind, readUTF(), readLong())
    }

    private fun DataOutputStream.writeChild(child: DesiredChild?) {
        writeBoolean(child != null)
        if (child != null) {
            writeUTF(child.runtimeId)
            writeLong(child.manifestRevision)
        }
    }

    private companion object {
        const val FORMAT_VERSION = 1
    }
}
