package com.typewritermc.engine.paper

import com.typewritermc.protocol.transport.generated.TRANSPORT_LIMITS
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsLifecycleResult
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.telemetry.InstrumentationScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import skirout.kernel.v1.errors.InternalError
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.EngineInstance
import skirout.service.v1.topology.OrganizationTopologySnapshot
import skirout.service.v1.topology.WatchOrganizationTopology
import skirout.service.v1.topology.WatchOrganizationTopologyRequest
import skirout.service.v1.topology.WatchOrganizationTopologyResponse
import java.nio.file.Path
import kotlin.io.path.readText
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * Reads the stack the game suite runs in, with the read only observer credentials `cargo xtask e2e game`
 * hands the test JVM: `STACK_NATS_URL`, `STACK_OBSERVER_CREDS`, `STACK_OBSERVER_INBOX` (the prefix its
 * replies arrive below) and `STACK_OBSERVER_TOPOLOGY` (the owner's topology snapshot request).
 */
class StackObserver private constructor(
    private val connection: NatsConnection,
    private val communicator: Communicator,
    private val topologySubject: String,
) : AutoCloseable {
    /** The organization topology as the backend holds it now. */
    suspend fun topology(): OrganizationTopologySnapshot {
        val contract =
            skirUnaryContract(
                WatchOrganizationTopology,
                OperationName.of("organization.topology.watch"),
                topologySubject.addressTemplate<Unit>({ addressValuesOf() }, { }),
                topologyResponses,
                { _, _ -> true },
            )
        return when (val result = communicator.request(contract, Unit, WatchOrganizationTopologyRequest.partial())) {
            is CommunicationResult.Success ->
                (result.value as? WatchOrganizationTopologyResponse.ListWrapper)?.value
                    ?: error("the topology snapshot request answered ${result.value}")
            is CommunicationResult.Failure -> error("the topology snapshot request failed: ${result.error}")
        }
    }

    /** The engine whose host's service is named [service], as the topology holds it now. */
    suspend fun engine(service: String): EngineInstance? = topology().engines.firstOrNull { it.ownerHost.name == service }

    /** Whether the engine of [service] reports active. */
    suspend fun active(service: String): Boolean = engine(service)?.state?.status == ChildRuntimeStatus.ACTIVE

    /** Waits up to [limit] until the engine of [service] reports active, and fails naming its last state. */
    suspend fun awaitActive(
        service: String,
        limit: Duration,
    ) {
        withTimeoutOrNull(limit) {
            while (!active(service)) delay(1.seconds)
        } ?: error("the engine of $service did not become active within $limit; it reads ${engine(service)?.state}")
    }

    override fun close() {
        kotlinx.coroutines.runBlocking { connection.shutdown() }
    }

    companion object {
        /** Connects to the stack the environment names. */
        suspend fun fromEnvironment(): StackObserver {
            fun env(name: String) =
                System.getenv(name)
                    ?: error("$name is not set: the Typewriter game requirements run inside the stack `cargo xtask e2e game` starts")
            val creds = Credentials.parse(Path.of(env("STACK_OBSERVER_CREDS")).readText())
            val connection =
                NatsConnection(
                    { NatsConnectionConfiguration(env("STACK_NATS_URL"), inboxPrefix = "${env("STACK_OBSERVER_INBOX")}.") },
                    { challenge -> NatsAuthentication(jwt = creds.jwt, signature = challenge.signNonce(creds.seed)) },
                )
            check(connection.connect() == NatsLifecycleResult.Success) { "the observer could not connect to the stack's NATS" }
            val telemetry = ServiceTelemetry(OpenTelemetry.noop(), InstrumentationScope("typewriter-game-tests"))
            val communicator =
                Communicator(NatsMessageTransport(connection, TRANSPORT_LIMITS), telemetry, OpenTelemetry.noop().propagators)
            return StackObserver(connection, communicator, env("STACK_OBSERVER_TOPOLOGY"))
        }

        private val topologyResponses =
            ResponsePolicy<WatchOrganizationTopologyResponse>(
                WatchOrganizationTopologyResponse.InternalErrorWrapper(InternalError.partial()),
            ) { response ->
                when (response.kind) {
                    WatchOrganizationTopologyResponse.Kind.LIST_WRAPPER -> ResponseClassification.success("list")
                    else -> ResponseClassification.internalError("internal-error")
                }
            }
    }
}

/** The JWT and seed of a NATS `.creds` file. */
private class Credentials(
    val jwt: String,
    val seed: String,
) {
    companion object {
        fun parse(text: String): Credentials {
            fun block(name: String) =
                Regex("-----BEGIN $name-----\\s*(\\S+)\\s*------END $name------").find(text)?.groupValues?.get(1)
                    ?: error("the observer credentials hold no $name")
            return Credentials(block("NATS USER JWT"), block("USER NKEY SEED"))
        }
    }
}
