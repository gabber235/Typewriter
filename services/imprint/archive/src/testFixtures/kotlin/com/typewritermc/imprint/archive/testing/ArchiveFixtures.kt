package com.typewritermc.imprint.archive.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import java.nio.file.Files
import java.nio.file.Path
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/** Writes a JAR at [path], with [manifest] as its Imprint manifest entry when one is given, and returns [path]. */
fun writeArchive(
    path: Path,
    manifest: ByteArray? = null,
): Path {
    ZipOutputStream(Files.newOutputStream(path)).use { output ->
        if (manifest != null) {
            output.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
            output.write(manifest)
            output.closeEntry()
        }
    }
    return path
}

/** A capability manifest for the test capability `typewritermc:test` with no requirements or contributions. */
fun capabilityManifest() =
    CapabilityManifest(
        id = ArtifactId("typewritermc:test"),
        version = ArtifactVersion("1.0.0"),
        directRequirements = emptyList(),
        resolvedCapabilities = emptyList(),
        contributions = emptyList(),
    )
