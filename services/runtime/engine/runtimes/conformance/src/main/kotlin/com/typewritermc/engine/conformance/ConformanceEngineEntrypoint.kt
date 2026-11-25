package com.typewritermc.engine.conformance

import com.typewritermc.engine.runtime.EngineDeployment
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.Session
import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.koin.dsl.bind
import org.koin.dsl.module

/** The parts of the conformance engine, which stands in for a game engine and keeps its sessions like one. */
val conformanceModule =
    module {
        single { SessionTimings.MINECRAFT }
        single { ConformanceSessions() } bind OnlineSessions::class
    }

/** The conformance engine's sessions: it has no players, so none. */
class ConformanceSessions : OnlineSessions {
    override val sessions: StateFlow<Set<Session>> = MutableStateFlow(emptySet<Session>()).asStateFlow()
}

/** Stages a conformance engine deployment. */
@ImprintRuntimeEntrypoint
class ConformanceEngineEntrypoint : HostedRuntimeEntrypoint by EngineDeployment(conformanceModule)
