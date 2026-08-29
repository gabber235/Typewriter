package com.typewritermc.loader

import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * Persists the stable control plane identity of one host for offline startup.
 *
 * Saving replaces the previous value through a sibling temporary file. Blank identities are rejected before touching
 * storage.
 */
class HostIdentityStore(
    private val path: Path,
) {
    fun load(): String? =
        if (Files.exists(path)) {
            Files.readString(path).trim().takeIf(String::isNotEmpty)
        } else {
            null
        }

    fun save(hostId: String) {
        require(hostId.isNotBlank()) { "Host id must not be blank." }
        Files.createDirectories(path.parent)
        val temporary = path.resolveSibling("${path.fileName}.tmp")
        Files.writeString(temporary, hostId)
        Files.move(temporary, path, StandardCopyOption.REPLACE_EXISTING)
    }
}
