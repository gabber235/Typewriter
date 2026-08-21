package com.typewritermc.engine.conformance

/** Records deterministic activation evidence for the maintained conformance engine fixture. */
interface ConformanceEngineGateway {
    fun record(value: String)
}
