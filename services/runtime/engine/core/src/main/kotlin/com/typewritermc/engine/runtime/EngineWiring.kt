package com.typewritermc.engine.runtime

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.engine.delivery.Delivery
import com.typewritermc.engine.delivery.DeliveryTimings
import com.typewritermc.engine.delivery.EngineLink
import com.typewritermc.engine.delivery.EventCodec
import com.typewritermc.engine.delivery.Inbox
import com.typewritermc.engine.delivery.InboxRegistrar
import com.typewritermc.engine.delivery.NatsEngineLink
import com.typewritermc.engine.delivery.Occurrences
import com.typewritermc.engine.events.ChainPickup
import com.typewritermc.engine.events.ChainQueue
import com.typewritermc.engine.events.ChainWorker
import com.typewritermc.engine.events.Elsewhere
import com.typewritermc.engine.events.EventParts
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.HandlerCosts
import com.typewritermc.engine.events.NoSubjectWork
import com.typewritermc.engine.events.SubjectHolding
import com.typewritermc.engine.events.SubjectWork
import com.typewritermc.engine.session.HeldSessions
import com.typewritermc.engine.session.SessionKeeper
import com.typewritermc.events.Emitter
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.SessionReporter
import com.typewritermc.identity.Sessions
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.protocol.transport.generated.SessionsBucket
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import org.koin.core.KoinApplication
import org.koin.core.module.Module
import org.koin.core.qualifier.named
import org.koin.dsl.bind
import org.koin.dsl.binds
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose
import skirout.editor.v1.type_catalog.PublicationId
import kotlin.reflect.KClass

/**
 * The Koin of one engine deployment: engine-core's parts, such as the engine's identity and its session keeping,
 * together with the module its engine kind brings. Every deployment has its own, so a reloaded engine leaves no class
 * behind and two engines in one process share nothing. Every single is built at once, so a missing dependency fails
 * the deployment's start and names the type; closing runs each single's close.
 */
internal class EngineWiring(
    context: HostedDeploymentContext,
    scope: CoroutineScope,
    kind: Module,
    parts: List<EnginePartProvider> = emptyList(),
    codec: EventCodec,
) : AutoCloseable {
    val application: KoinApplication =
        koinApplication {
            allowOverride(false)
            modules(engineCoreModule(context, scope, codec), enginePartModule(parts), kind)
            createEagerInstances()
        }

    /** The engine this deployment runs as, which each publication's book conditions are asked on. */
    val identity: Engine get() = application.koin.get()

    /** The event runtime of this deployment, which each publication is handed to. */
    val events: EventRuntime get() = application.koin.get()

    /**
     * Tells every [PublicationObserver] part that the engine applied [publication].
     *
     * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
     */
    fun applied(publication: PublicationId) {
        application.koin.getAll<PublicationObserver>().forEach { it.applied(publication) }
    }

    /** The activation work the engine kind declared, run with every activation of the deployment. */
    val registrars: List<RuntimeRegistrar> get() = application.koin.getAll<RuntimeRegistrar>()

    override fun close() = application.close()
}

private fun engineCoreModule(
    context: HostedDeploymentContext,
    scope: CoroutineScope,
    codec: EventCodec,
) = module {
    single { context.identity }
    single { context.host }
    single { Engine(EngineId(requireNotNull(context.identity.engineId) { "An engine deployment needs the engine id its host assigned." })) }
    single(createdAtStart = true) {
        SessionKeeper(
            engine = get<Engine>().id,
            buckets =
                context.host.messaging.map { it?.buckets }.stateIn(
                    scope,
                    SharingStarted.Eagerly,
                    context.host.messaging.value
                        ?.buckets,
                ),
            bucketName = SessionsBucket.name(context.identity.realmId),
            timings = get(),
            holding = get(),
            // The keeper decides itself that this engine holds the subject of every event it fires.
            events = get<EventRuntime>().asHolder,
            parent = scope,
        )
    } onClose { it?.close() } binds arrayOf(SessionReporter::class, Sessions::class)
    single { HeldSessions(get<Engine>().id) } bind SubjectHolding::class
    single<EventCodec> { codec }
    single<EngineLink> { NatsEngineLink(context.host.messaging, context.identity.realmId, get<Engine>().id) }
    single {
        Delivery(get<Engine>().id, get(), get<SessionKeeper>().copy, get(), get(), get(), scope, getOrNull<DeliveryTimings>() ?: DeliveryTimings())
    } binds arrayOf(Emitter::class, Elsewhere::class)
    single { Inbox(get(), get(), get(), Occurrences(scope, getOrNull<DeliveryTimings>() ?: DeliveryTimings())) }
    // Named, since an engine kind binds its own registrars to the same type.
    single(named("inbox")) { InboxRegistrar(get(), get()) } bind RuntimeRegistrar::class
    single { ChainQueue(subjectWork(getAll())) }
    single { ChainWorker(get(), scope) }
    single { HandlerCosts(context.host.openTelemetry) }
    single(createdAtStart = true) {
        EventRuntime(
            EventParts(handlers = getAll(), shapes = getAll(), sources = getAll(), subscribed = getAll(), live = getAll()),
            get(),
            get(),
            getOrNull<ChainPickup>()
                ?: error("This engine kind provides no ChainPickup, so the chains its events queue would never run."),
            get(),
            // Delivery runs occurrences through this runtime, so the runtime reaches it only once both exist.
            lazy { get<Elsewhere>() },
        )
    } onClose { it?.close() }
}

/** The one part that counts chain work, or the production default when none does; two would each miss half the work. */
private fun subjectWork(parts: List<SubjectWork>): SubjectWork {
    require(parts.size <= 1) {
        "Only one SubjectWork may count chain work, but this engine has ${parts.joinToString { it::class.simpleName.toString() }}."
    }
    return parts.singleOrNull() ?: NoSubjectWork
}

/**
 * One single per generated engine part, bound to every supertype it declares, so handlers, sources, and resolvers are
 * found by their role. A part's constructor parameters come from this Koin; one it cannot provide fails the start and
 * names both types.
 */
private fun enginePartModule(parts: List<EnginePartProvider>) =
    module {
        parts.forEach { part ->
            single(named(part.type.java.name), createdAtStart = true) {
                val scope = this
                part.create(
                    object : EnginePartDependencies {
                        override fun <T : Any> get(type: KClass<T>): T =
                            scope.getOrNull(type)
                                ?: error("${part.type.simpleName} needs ${type.simpleName}, which this engine does not provide.")
                    },
                )
            } binds part.binds.toTypedArray()
        }
    }
