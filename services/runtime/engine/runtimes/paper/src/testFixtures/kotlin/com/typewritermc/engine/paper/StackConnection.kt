package com.typewritermc.engine.paper

import com.typewritermc.protocol.transport.generated.TRANSPORT_LIMITS
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.telemetry.InstrumentationScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.api.OpenTelemetry
import java.nio.file.Path
import kotlin.io.path.readText

/**
 * A connection to the stack's NATS as one of the users `cargo xtask e2e game` mints for the game requirements, and the
 * communicator that requests over it.
 */
internal class StackConnection private constructor(
    val connection: NatsConnection,
    val communicator: Communicator,
) : AutoCloseable {
    override fun close() {
        kotlinx.coroutines.runBlocking { connection.shutdown() }
    }

    companion object {
        /**
         * Connects as the user whose `.creds` file the variable [creds] names, receiving replies below the inbox prefix
         * the variable [inbox] holds; [user] names the user in failures.
         */
        suspend fun open(
            user: String,
            creds: String,
            inbox: String,
        ): StackConnection {
            val credentials = Credentials.parse(user, Path.of(stackValue(creds)).readText())
            val connection =
                NatsConnection(
                    { NatsConnectionConfiguration(stackValue("STACK_NATS_URL"), inboxPrefix = "${stackValue(inbox)}.") },
                    { challenge -> NatsAuthentication(jwt = credentials.jwt, signature = challenge.signNonce(credentials.seed)) },
                )
            check(connection.connect() == NatsLifecycleResult.Success) { "the $user could not connect to the stack's NATS" }
            val telemetry = ServiceTelemetry(OpenTelemetry.noop(), InstrumentationScope("typewriter-game-tests"))
            return StackConnection(
                connection,
                Communicator(NatsMessageTransport(connection, TRANSPORT_LIMITS), telemetry, OpenTelemetry.noop().propagators),
            )
        }
    }
}

/** The stack value [name] that `cargo xtask e2e game` hands the test JVM. */
internal fun stackValue(name: String): String =
    System.getenv(name)
        ?: error("$name is not set: the Typewriter game requirements run inside the stack `cargo xtask e2e game` starts")

/** The JWT and seed of a NATS `.creds` file. */
private class Credentials(
    val jwt: String,
    val seed: String,
) {
    companion object {
        fun parse(
            user: String,
            text: String,
        ): Credentials {
            fun block(name: String) =
                Regex("-----BEGIN $name-----\\s*(\\S+)\\s*------END $name------").find(text)?.groupValues?.get(1)
                    ?: error("the $user credentials hold no $name")
            return Credentials(block("NATS USER JWT"), block("USER NKEY SEED"))
        }
    }
}
