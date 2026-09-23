package com.typewritermc.realm.repository

import com.typewritermc.discovery.AssembledTypeDiscovery
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.PrototypeRegistryLoader
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypePrototypeRegistry

internal fun loadTestPrototypes(): TypePrototypeRegistry {
    val classLoader = object {}.javaClass.classLoader
    val contributions =
        classLoader
            .getResources("META-INF/typewriter/contributions/types/declared.cbor")
            .toList()
            .map { resource -> resource.openStream().use { TypeDiscoveryContributionCodec.decode(it.readAllBytes()) } }
    val definitions =
        (StandardTypes.definitions + contributions.flatMap { it.definitions })
            .distinctBy { it.id }
    val relations = contributions.flatMap { it.relations }.distinctBy { it.id }
    val prototypeBindings = contributions.flatMap { it.prototypeBindings }.distinctBy { it.type }
    return PrototypeRegistryLoader().load(
        AssembledTypeDiscovery(
            catalog = TypeCatalog(definitions),
            relations = relations,
            prototypeBindings = prototypeBindings,
            executableBindings = emptyList(),
        ),
        DiscoveryDomains.Realm,
        classLoader,
    )
}
