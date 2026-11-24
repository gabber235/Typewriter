package com.typewritermc.engine.runtime

import com.typewritermc.discovery.RuntimeRegistrar
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
import org.koin.dsl.binds
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import org.koin.dsl.onClose

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
) : AutoCloseable {
    val application: KoinApplication =
        koinApplication {
            allowOverride(false)
            modules(engineCoreModule(context, scope), kind)
            createEagerInstances()
        }

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
            openTelemetry = context.host.openTelemetry,
        )
    } onClose { it?.close() } binds arrayOf(SessionReporter::class, Sessions::class)
}
