package com.typewritermc.playtest.pool

import java.io.OutputStream
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.security.DigestInputStream
import java.security.MessageDigest
import java.util.HexFormat

/**
 * Java's ahead of time cache for Paper's boot, kept in [dir] across runs. A cache only fits the exact
 * JDK, class path, plugins and flags it was trained with, so each lives under a [key] of all of them; a
 * boot whose key has no cache trains one as it runs, and a trained cache replaces every cache of an
 * older key.
 */
internal class AotCache(
    private val dir: Path,
) {
    /** How one boot uses the cache: the JVM flags it adds. */
    sealed interface Boot {
        val flags: List<String>

        /** Boots from the trained [cache]. */
        data class Use(
            val cache: Path,
        ) : Boot {
            override val flags get() = listOf("-XX:AOTCache=$cache")
        }

        /** Trains a cache as it runs; the JVM writes it to [output] once it exits. */
        data class Train(
            val key: String,
            val output: Path,
        ) : Boot {
            override val flags get() = listOf("-XX:AOTCacheOutput=$output")
        }
    }

    /** How the boot of the Paper [paper] with [key] uses the cache. */
    fun boot(
        key: String,
        paper: String,
    ): Boot {
        val cache = dir.resolve("$key.aot")
        if (Files.isRegularFile(cache)) return Boot.Use(cache)
        Files.createDirectories(dir)
        return Boot.Train(key, dir.resolve("$key.$paper.training"))
    }

    /**
     * The training boot [train] exited with [code]: a complete cache becomes the cache, anything else is
     * removed. A JVM writes its cache as it exits of its own accord, even through a halt, and removes the
     * configuration it recorded once the cache is written; killed by a signal (code 128 and up) it writes
     * none.
     */
    fun trained(
        train: Boot.Train,
        code: Int,
    ) {
        // A JVM that fails to write its cache can leave a file that looks like one and that no boot can map.
        val configuration = train.output.resolveSibling("${train.output.fileName}.config")
        val complete = code < KILLED && Files.isRegularFile(train.output) && Files.size(train.output) > 0 && !Files.exists(configuration)
        if (!complete) {
            Files.deleteIfExists(train.output)
            Files.deleteIfExists(configuration)
            return
        }
        Files.move(train.output, dir.resolve("${train.key}.aot"), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
        // Training boots of the same key may still run; every file of an older key goes.
        Files.list(dir).use { files -> files.filter { !it.fileName.toString().startsWith("${train.key}.") }.toList() }.forEach(Files::deleteIfExists)
    }

    companion object {
        /** The key of a cache trained on the JDK [jdk], with [files] on its class path and in its plugins, and [flags]. */
        fun key(
            jdk: String,
            files: List<Path>,
            flags: List<String>,
        ): String {
            val digest = MessageDigest.getInstance("SHA-256")
            fun part(text: String) = digest.update("$text\u0000".toByteArray())
            part(jdk)
            // A file's content, never its time: a rebuilt but equal jar keeps the cache. Java 25 maps a
            // cache over changed jars without a word, so a changed jar must change the key.
            for (file in files) {
                part(file.fileName.toString())
                Files.newInputStream(file).use { input -> DigestInputStream(input, digest).use { it.transferTo(OutputStream.nullOutputStream()) } }
            }
            flags.forEach(::part)
            return HexFormat.of().formatHex(digest.digest()).take(KEY_LENGTH)
        }

        private const val KEY_LENGTH = 32

        /** Exit codes from here on mean a signal ended the process. */
        private const val KILLED = 128
    }
}
