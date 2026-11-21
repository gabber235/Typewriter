package com.typewritermc.engine.runtime

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.engine.events.ChainQueue
import com.typewritermc.engine.events.EventParts
import com.typewritermc.engine.events.EventRuntime
import com.typewritermc.engine.events.NoSubjectWork
import com.typewritermc.engine.events.SubjectWork
import com.typewritermc.events.EnginePartDependencies
import com.typewritermc.events.EnginePartProvider
import com.typewritermc.engine.session.SessionKeeper
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
import org.koin.dsl.binds
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose
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
) : AutoCloseable {
    val application: KoinApplication =
        koinApplication {
            allowOverride(false)
            modules(engineCoreModule(context, scope), enginePartModule(parts), kind)
            createEagerInstances()
        }

    /** The event runtime of this deployment, which each publication is handed to. */
    val events: EventRuntime get() = application.koin.get()

    /** The activation work the engine kind declared, run with every activation of the deployment. */
    val registrars: List<RuntimeRegistrar> get() = application.koin.getAll<RuntimeRegistrar>()

    override fun close() = application.close()
}

private fun engineCoreModule(
    context: HostedDeploymentContext,
    scope: CoroutineScope,
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
            parent = scope,
        )
    } onClose { it?.close() } binds arrayOf(SessionReporter::class, Sessions::class)
    single { ChainQueue(getAll<SubjectWork>().singleOrNull() ?: NoSubjectWork) }
    single(createdAtStart = true) {
        EventRuntime(EventParts(handlers = getAll(), shapes = getAll(), sources = getAll(), live = getAll()), get())
    } onClose { it?.close() }
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
                            scope.getOrNull(type) ?: error("${part.type.simpleName} needs ${type.simpleName}, which this engine does not provide.")
                    },
                )
            } binds part.binds.toTypedArray()
        }
    }
