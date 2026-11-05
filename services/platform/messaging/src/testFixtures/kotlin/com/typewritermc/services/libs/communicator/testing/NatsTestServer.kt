package com.typewritermc.services.libs.communicator.testing

import java.io.BufferedReader
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import kotlin.concurrent.thread
import kotlin.io.path.deleteRecursively
import kotlin.io.path.writeText

/**
 * A real nats-server process for tests that need what only the broker enforces: permissions, max_payload, queue
 * groups. Every test run starts its own, so no test depends on a broker someone else started.
 *
 * The server is the pinned binary devenv names in `NATS_SERVER_BIN`, the one the backend broker fixture starts too.
 * [start] runs [config] on a random loopback client port, which overrides the config's own `port`; close stops the
 * process and removes its state.
 */
class NatsTestServer private constructor(
    /** The client URL, such as `nats://127.0.0.1:53124`. */
    val url: String,
    private val process: Process,
    private val state: Path,
) : AutoCloseable {
    @OptIn(kotlin.io.path.ExperimentalPathApi::class)
    override fun close() {
        process.destroy()
        if (!process.waitFor(STOP_TIMEOUT_SECONDS, TimeUnit.SECONDS)) process.destroyForcibly().waitFor()
        state.deleteRecursively()
    }

    companion object {
        /** Starts a server on [config], a nats-server configuration file's text, and waits until it accepts clients. */
        fun start(config: String = ""): NatsTestServer {
            val state = Files.createTempDirectory("nats-test-server")
            val file = state.resolve("nats.conf")
            file.writeText(config)
            val binary = System.getenv("NATS_SERVER_BIN") ?: "nats-server"
            val process =
                ProcessBuilder(binary, "--config", file.toString(), "--addr", "127.0.0.1", "--port", "-1")
                    .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                    .start()
            val ready = CompletableFuture<String>()
            thread(isDaemon = true, name = "nats-test-server-log") { process.errorStream.bufferedReader().announceReady(ready) }
            val url =
                try {
                    ready.get(STARTUP_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                } catch (timeout: TimeoutException) {
                    process.destroyForcibly()
                    throw IllegalStateException("$binary did not become ready within $STARTUP_TIMEOUT_SECONDS seconds", timeout)
                }
            return NatsTestServer(url, process, state)
        }

        /**
         * Completes [ready] with the client URL once the server logs that it is ready, or fails it with the log when
         * the server exits first; then keeps draining, so the server never blocks on a full pipe.
         */
        private fun BufferedReader.announceReady(ready: CompletableFuture<String>) {
            val log = mutableListOf<String>()
            var url: String? = null
            for (line in lineSequence()) {
                if (ready.isDone) continue
                log += line
                line.substringAfter("Listening for client connections on ", "").takeIf { it.isNotBlank() }?.let {
                    url = "nats://${it.trim()}"
                }
                if ("Server is ready" in line) {
                    url?.let(ready::complete)
                        ?: ready.completeExceptionally(IllegalStateException("nats-server was ready without a client address"))
                }
            }
            ready.completeExceptionally(IllegalStateException("nats-server exited before it was ready: ${log.joinToString(" | ")}"))
        }

        private const val STARTUP_TIMEOUT_SECONDS = 10L
        private const val STOP_TIMEOUT_SECONDS = 5L
    }
}
