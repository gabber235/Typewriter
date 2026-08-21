package com.typewritermc.loader.standalone

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderBootstrap
import com.typewritermc.loader.standalone.shell.LoaderConsoleLogOutput
import com.typewritermc.loader.standalone.shell.LoaderShell
import com.typewritermc.loader.standalone.shell.LoaderShellContext
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import java.nio.file.Path
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.io.path.Path

/**
 * Runs the combined loader JAR as a standalone service host.
 *
 * The optional first argument selects the working directory. [run] owns the shell and guarantees host cleanup after an
 * operator stop, end of input, failure, cancellation, or process shutdown.
 */
object StandaloneLoader {
    @JvmStatic
    fun main(args: Array<String>) {
        runBlocking {
            val workDirectory = args.firstOrNull()?.let(::Path) ?: Path.of("typewriter")
            localLoaderApplication().use { application ->
                run(workDirectory, application.bootstrap, application.telemetry, application.console)
            }
        }
    }

    suspend fun run(
        workDirectory: Path,
        bootstrap: LoaderBootstrap,
        telemetry: ServiceTelemetry,
        console: LoaderConsoleLogOutput,
    ) = coroutineScope {
        val host = bootstrap.start(HostEntrypoint.STANDALONE, workDirectory, this)
        val stopped = AtomicBoolean()

        suspend fun stop() {
            if (stopped.compareAndSet(false, true)) host.stop()
        }
        val shutdownHook = Thread { runBlocking { stop() } }
        Runtime.getRuntime().addShutdownHook(shutdownHook)
        try {
            val context = LoaderShellContext(host.service.states, kotlin.time.TimeSource.Monotonic)
            withContext(Dispatchers.IO) { LoaderShell(context, telemetry, console).run() }
        } finally {
            runCatching { Runtime.getRuntime().removeShutdownHook(shutdownHook) }
            stop()
        }
    }
}
