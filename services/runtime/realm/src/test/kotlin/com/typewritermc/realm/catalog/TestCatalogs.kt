package com.typewritermc.realm.catalog

import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble
import skirout.editor.v1.type_catalog.CatalogGeneration

internal fun RealmCatalogStore.installTestCatalog(generation: String) {
    replace(testCatalogIncarnation(generation))
}

internal fun testCatalogIncarnation(generation: String): RealmCatalogIncarnation {
    val deployment = GeneratedProviderLoader().load(emptyList(), DeploymentFacts(), DiscoveryDomains.Realm)
    val contributions = deployment.providers.contributions
    val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = generation)))
    return RealmCatalogIncarnation(assembly, deployment)
}
