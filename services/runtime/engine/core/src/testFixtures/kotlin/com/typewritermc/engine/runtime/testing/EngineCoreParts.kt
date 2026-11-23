package com.typewritermc.engine.runtime.testing

import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.engine.runtime.EngineWiring
import com.typewritermc.events.EnginePartProvider

/** The engine parts engine core's own source part generated, loaded from its provider index as a deployment loads them. */
fun engineCoreParts(): List<EnginePartProvider> {
    val loader = EngineWiring::class.java.classLoader
    return loader
        .getResources(GENERATED_PROVIDER_INDEX_PATH)
        .toList()
        .flatMap { GeneratedProviderIndex.parse(it.readText()) }
        .filter { it.kind == GeneratedProviderKind.EnginePart && it.sourcePart == "main" }
        .map { loader.loadClass(it.providerClass).getDeclaredConstructor().newInstance() as EnginePartProvider }
}
