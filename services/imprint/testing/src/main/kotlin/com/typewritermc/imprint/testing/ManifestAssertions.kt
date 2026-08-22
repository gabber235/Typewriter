package com.typewritermc.imprint.testing

import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import java.io.File
import java.util.zip.ZipFile

/** Reads the single canonical Imprint manifest from an artifact JAR. */
fun File.readImprintManifest(): ImprintManifest =
    ZipFile(this).use { archive ->
        val entry =
            requireNotNull(archive.getEntry(IMPRINT_MANIFEST_PATH)) {
                "Artifact $name does not contain $IMPRINT_MANIFEST_PATH."
            }
        ImprintManifestCodec.decode(archive.getInputStream(entry).readBytes())
    }

/** Fails when a JAR does not contain exactly one canonical Imprint manifest. */
fun File.requireSingleImprintManifest(): ImprintManifest =
    ZipFile(this).use { archive ->
        val entries =
            archive
                .entries()
                .asSequence()
                .filter { it.name == IMPRINT_MANIFEST_PATH }
                .toList()
        require(entries.size == 1) {
            "Artifact $name contains ${entries.size} canonical Imprint manifests."
        }
        ImprintManifestCodec.decode(archive.getInputStream(entries.single()).readBytes())
    }
