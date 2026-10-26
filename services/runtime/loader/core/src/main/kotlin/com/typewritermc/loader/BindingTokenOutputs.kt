package com.typewritermc.loader

import com.typewritermc.services.libs.registrar.console.BindingTokenOutput
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.attribute.PosixFilePermission
import java.nio.file.attribute.PosixFilePermissions

/**
 * Writes the pending registration token to [file] so automation, such as the worktree stack's `bind`, can bind a
 * headless host without reading its console. The token rotates while pending, so each write atomically replaces the
 * previous one. The token is as sensitive as the console line, so the file is created owner readable only where the
 * file system supports POSIX permissions and with the platform default elsewhere; it is removed once cleared.
 */
internal class FileBindingTokenOutput(
    private val file: Path,
) : BindingTokenOutput {
    override fun display(token: String) {
        val parent = file.toAbsolutePath().parent
        Files.createDirectories(parent)
        val prefix = ".${file.fileName}."
        val temporary =
            if ("posix" in parent.fileSystem.supportedFileAttributeViews()) {
                Files.createTempFile(parent, prefix, ".tmp", PosixFilePermissions.asFileAttribute(OWNER_ONLY))
            } else {
                Files.createTempFile(parent, prefix, ".tmp")
            }
        try {
            Files.writeString(temporary, token)
            try {
                Files.move(temporary, file, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
            } catch (_: AtomicMoveNotSupportedException) {
                Files.move(temporary, file, StandardCopyOption.REPLACE_EXISTING)
            }
        } finally {
            Files.deleteIfExists(temporary)
        }
    }

    override fun cleared() {
        Files.deleteIfExists(file)
    }

    private companion object {
        val OWNER_ONLY = setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE)
    }
}

/** Sends each token event to every output in order. */
internal class BindingTokenOutputs(
    private vararg val outputs: BindingTokenOutput,
) : BindingTokenOutput {
    override fun display(token: String) = outputs.forEach { it.display(token) }

    override fun cleared() = outputs.forEach { it.cleared() }
}
