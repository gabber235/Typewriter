package com.typewritermc.engine.delivery.testing

import com.typewritermc.engine.delivery.DeliveryTimings
import com.typewritermc.engine.delivery.EventCodec
import com.typewritermc.engine.runtime.testing.WiredEngine
import com.typewritermc.engine.runtime.testing.testEngineKind
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Protagonist
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.protocol.transport.generated.serviceReplyInboxPrefix
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.testing.BrokerClients
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.onBroker
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import org.koin.core.module.Module
import org.koin.dsl.module
import kotlin.time.Duration.Companion.seconds

/**
 * Engines of Realm `realm` on one NATS broker with JetStream, each a [WiredEngine] with its own connections, so events
 * cross between them as between hosts. Every engine closes when the block ends.
 */
class DeliveryHarness private constructor(
    private val clients: BrokerClients,
) {
    private val engines = mutableListOf<WiredEngine>()

    /**
     * A wired engine [id] of engine kind [kind] with [parts], crossing events with [codec] and waiting by [timings],
     * whose event asks and answers go through [lossy].
     */
    suspend fun engine(
        id: String,
        parts: List<EnginePartProvider> = emptyList(),
        codec: EventCodec = TestEventCodec(),
        timings: DeliveryTimings = DeliveryTimings(),
        kind: Module = testEngineKind(),
        lossy: (LossyTransport) -> Unit = {},
    ): WiredEngine {
        val wired =
            module {
                includes(kind)
                single { timings }
            }
        // An engine's host asks from its service reply inbox, the only one the inbox route answers.
        val transport = LossyTransport(clients.transport(inboxPrefix = "${serviceReplyInboxPrefix(id)}.")).also(lossy)
        return WiredEngine(wired, parts, clients.buckets(), id, transport, codec).also { engines += it }
    }

    /**
     * A panel tab [session] of user [user] in organization `organization`: its connection answers from the tab's own
     * reply inboxes, `_INBOX.<user>.<session>.<token>`, as the panel's do.
     */
    suspend fun tab(
        user: String,
        session: String,
    ): Communicator =
        Communicator(
            clients.transport(inboxPrefix = "_INBOX.$user.$session."),
            OpenTelemetry.noop().serviceTelemetry("panel tab"),
            ContextPropagators.noop(),
        )

    /** Waits until [engine] sees exactly [holders] holding [protagonist]. */
    suspend fun sees(
        engine: WiredEngine,
        protagonist: Protagonist,
        vararg holders: String,
    ) = eventually(10.seconds) { engine.sessions.holders(protagonist) shouldBe holders.mapTo(mutableSetOf(), ::EngineId) }

    companion object {
        suspend fun run(block: suspend DeliveryHarness.() -> Unit) {
            NatsTestServer.startWithJetStream().use { server ->
                onBroker(server.url) {
                    check(buckets().ensure(SessionsBucket.declaration("realm")) is KeyValueOpen.Opened)
                    val harness = DeliveryHarness(this)
                    try {
                        harness.block()
                    } finally {
                        harness.engines.forEach { it.close() }
                    }
                }
            }
        }
    }
}
