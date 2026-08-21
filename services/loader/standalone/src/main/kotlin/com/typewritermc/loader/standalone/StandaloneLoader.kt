package com.typewritermc.loader.standalone

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderBootstrap
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.runBlocking
import java.nio.file.Path
import kotlin.io.path.Path

/**
 * Runs the combined loader JAR as a standalone service host.
 *
 * The optional first argument selects the working directory. [run] remains suspended for the process lifetime and always
 * stops the host when its coroutine is cancelled.
 */
object StandaloneLoader {
    @JvmStatic
    fun main(args: Array<String>) {
        runBlocking {
            val workDirectory = args.firstOrNull()?.let(::Path) ?: Path.of("typewriter")
            localLoaderApplication().use { application -> run(workDirectory, application.bootstrap) }
        }
    }

    suspend fun run(
        workDirectory: Path,
        bootstrap: LoaderBootstrap,
    ): Nothing =
        coroutineScope {
            val host = bootstrap.start(HostEntrypoint.STANDALONE, workDirectory, this)
            try {
                awaitCancellation()
            } finally {
                host.stop()
            }
        }
}
