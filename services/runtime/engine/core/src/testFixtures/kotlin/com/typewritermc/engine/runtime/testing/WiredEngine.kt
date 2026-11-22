package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.events.ChainPickup
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.ImmediateChainPickup
import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.runtime.EngineWiring
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.identity.SessionReporter
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.testing.UnreachableKeyValueBuckets
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.core.module.Module
import org.koin.dsl.module
import skirout.editor.v1.type_catalog.PublicationId

/**
 * One engine deployment's Koin, wired as a deployment wires it from the engine kind's [kind] module and the generated
 * [parts], as engine `engine` of Realm `realm` on a host whose messaging reaches [buckets]. It starts with empty
 * published content; closing closes the Koin and its coroutine scope.
 */
class WiredEngine(
    kind: Module,
    parts: List<EnginePartProvider> = emptyList(),
    buckets: KeyValueBuckets = UnreachableKeyValueBuckets,
) : AutoCloseable {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val wiring =
        try {
            EngineWiring(wiredDeploymentContext(buckets), scope, kind, parts)
        } catch (failure: Throwable) {
            scope.cancel()
            throw failure
        }

    init {
        wiring.events.publish(PublishedEntries.EMPTY)
    }

    /** The event runtime of the engine. */
    val events: EventRuntime get() = wiring.events

    /** Where the engine's kind reports sessions. */
    val reporter: SessionReporter get() = wiring.application.koin.get()

    /** The engine applied [publication], which it now runs. */
    fun applied(publication: PublicationId) = wiring.applied(publication)

    override fun close() {
        wiring.close()
        scope.cancel()
    }
}

/** Every message of [failure] and its causes, joined, so a test can find the one that names a missing part. */
fun messagesOf(failure: Throwable): String = generateSequence(failure) { it.cause }.joinToString(" | ") { it.message.orEmpty() }

/** The engine kind of a wired test engine: the harness's short session timings, and chains that run at once. */
val testEngineKind: Module =
    module {
        single<SessionTimings> { SessionHarness.SHORT }
        single<ChainPickup> { ImmediateChainPickup(get()) }
    }
