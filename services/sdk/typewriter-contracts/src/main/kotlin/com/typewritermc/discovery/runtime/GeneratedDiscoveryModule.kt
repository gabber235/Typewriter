package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.ContributionKey
import org.koin.core.module.Module

/** Factory contract implemented by generated contribution modules. */
interface GeneratedDiscoveryModule {
    /** Builds the runtime bindings associated with [contribution]. */
    fun module(contribution: ContributionKey): Module
}
