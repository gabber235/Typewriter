package com.typewritermc.loader.standalone

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderBootstrap
import com.typewritermc.loader.loaderApplication
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
 * Process entrypoint that owns the loader application, running host, and interactive shell. The first argument
 * selects the work directory, defaulting to typewriter. Normal shell exit and the JVM shutdown hook share a
 * guarded stop path so teardown is requested once; application closure follows host shutdown.
 */
object StandaloneLoader {
    @JvmStatic
    fun main(args: Array<String>) {
        runBlocking {
            val workDirectory = args.firstOrNull()?.let(::Path) ?: Path.of("typewriter")
            val console = LoaderConsoleLogOutput()
            loaderApplication(console).use { application ->
                run(workDirectory, application.bootstrap, application.telemetry, console)
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
