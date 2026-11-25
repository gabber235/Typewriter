package com.typewritermc.engine.panel

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.engine.runtime.EngineDeployment
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeIdentity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import org.koin.dsl.bind
import org.koin.dsl.module
import org.koin.dsl.onClose

/** The parts of a panel engine, whose sessions are the panel tabs in its Realm, each a session of the tab's user. */
val panelModule =
    module {
        single { SessionTimings.PANEL }
        single {
            PresenceSessions(get<HostedRuntimeIdentity>().realmId, get(), CoroutineScope(SupervisorJob() + Dispatchers.Default))
        } onClose { it?.close() } bind OnlineSessions::class
        single { PresenceSessionsRegistrar(get(), get()) } bind RuntimeRegistrar::class
    }

/** Stages a panel engine deployment. */
@ImprintRuntimeEntrypoint
class PanelEngineEntrypoint : HostedRuntimeEntrypoint by EngineDeployment(panelModule)
