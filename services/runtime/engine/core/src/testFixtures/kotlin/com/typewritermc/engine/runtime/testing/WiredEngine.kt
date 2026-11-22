package com.typewritermc.engine.runtime.testing

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.delivery.EngineLink
import com.typewritermc.engine.delivery.EventCodec
import com.typewritermc.engine.delivery.testing.TestEventCodec
import com.typewritermc.engine.events.ChainPickup
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.ImmediateChainPickup
import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.runtime.EngineWiring
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.events.Emitter
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.identity.SessionReporter
import com.typewritermc.identity.Sessions
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.testing.UnreachableKeyValueBuckets
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import org.koin.core.module.Module
import org.koin.dsl.module
import skirout.editor.v1.type_catalog.PublicationId

/**
 * One engine deployment's Koin, wired as a deployment wires it from the engine kind's [kind] module and the generated
 * [parts], as engine [id] of Realm `realm` on a host whose messaging reaches [buckets] and sends through [transport],
 * crossing events with [codec]. It starts active, running the deployment's registrars, with empty published content;
 * closing closes the Koin and its coroutine scope.
 */
class WiredEngine(
    kind: Module,
    parts: List<EnginePartProvider> = emptyList(),
    buckets: KeyValueBuckets = UnreachableKeyValueBuckets,
    val id: String = "engine",
    transport: MessageTransport = FakeMessageTransport(),
    codec: EventCodec = TestEventCodec(),
) : AutoCloseable {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val wiring =
        try {
            EngineWiring(wiredDeploymentContext(buckets, id, transport), scope, kind, parts, codec)
        } catch (failure: Throwable) {
            scope.cancel()
            throw failure
        }

    init {
        wiring.events.publish(PublishedEntries.EMPTY)
        val active =
            object : RuntimeScope {
                override val coroutineScope = scope
                override val facts = DeploymentFacts(emptyMap())

                override fun own(cleanup: suspend () -> Unit) = Unit

                override fun <R : AutoCloseable> own(resource: R): R = resource
            }
        runBlocking { wiring.registrars.forEach { with(active) { it.register() } } }
    }

    /** What the engine's handlers send events with, waiting for the merged result of every holder. */
    val emitter: Emitter get() = wiring.application.koin.get()

    /** The event runtime of the engine. */
    val events: EventRuntime get() = wiring.events

    /** Where the engine's kind reports sessions. */
    val reporter: SessionReporter get() = wiring.application.koin.get()

    /** How this engine reaches the event inboxes of other engines. */
    val link: EngineLink get() = wiring.application.koin.get()

    /** The Realm's sessions as this engine sees them. */
    val sessions: Sessions get() = wiring.application.koin.get()

    /** The engine applied [publication], which it now runs. */
    fun applied(publication: PublicationId) = wiring.applied(publication)

    override fun close() {
        wiring.close()
        scope.cancel()
    }
}

/** Every message of [failure] and its causes, joined, so a test can find the one that names a missing part. */
fun messagesOf(failure: Throwable): String = generateSequence(failure) { it.cause }.joinToString(" | ") { it.message.orEmpty() }

/**
 * The engine kind of a wired test engine: the harness's short session timings, and chains that run at once. Each call
 * is a new module, since a Koin module keeps the instances of its singles and two engines must share none.
 */
fun testEngineKind(): Module =
    module {
        single<SessionTimings> { SessionHarness.SHORT }
        single<ChainPickup> { ImmediateChainPickup(get()) }
    }
