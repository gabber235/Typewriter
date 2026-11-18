package com.typewritermc.engine.panel

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.engine.runtime.EngineDeployment
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeIdentity
import org.koin.dsl.bind
import org.koin.dsl.module

/** The parts of a panel engine, which reports each panel tab in its Realm as a session of the tab's user. */
val panelModule =
    module {
        single { SessionTimings.PANEL }
        single { PresenceSessions(get<HostedRuntimeIdentity>().realmId, get(), get()) }
        single { PresenceSessionsRegistrar(get(), get()) } bind RuntimeRegistrar::class
    }

/** Stages a panel engine deployment. */
@ImprintRuntimeEntrypoint
class PanelEngineEntrypoint : HostedRuntimeEntrypoint by EngineDeployment(panelModule)
