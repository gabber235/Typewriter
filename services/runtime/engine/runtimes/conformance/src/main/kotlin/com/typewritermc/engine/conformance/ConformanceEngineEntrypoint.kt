package com.typewritermc.engine.conformance

import com.typewritermc.engine.events.ChainPickup
import com.typewritermc.engine.events.ImmediateChainPickup
import com.typewritermc.engine.runtime.EngineDeployment
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import org.koin.dsl.module

/**
 * The parts of the conformance engine, which stands in for a game engine and keeps its sessions like one. It has no
 * ticks, so every queued chain runs at once.
 */
val conformanceModule =
    module {
        single { SessionTimings.MINECRAFT }
        single<ChainPickup> { ImmediateChainPickup(get()) }
    }

/** Stages a conformance engine deployment. */
@ImprintRuntimeEntrypoint
class ConformanceEngineEntrypoint : HostedRuntimeEntrypoint by EngineDeployment(conformanceModule)
