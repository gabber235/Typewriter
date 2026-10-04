package com.typewritermc.realm.catalog

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble

internal fun RealmCatalogStore.installTestCatalog(generation: String) {
    replace(testCatalogIncarnation(generation))
}

internal fun testCatalogIncarnation(generation: String): RealmCatalogIncarnation {
    val deployment = GeneratedProviderLoader().load(emptyList(), DeploymentFacts())
    val contributions = deployment.providers.contributions
    val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration(generation)))
    return RealmCatalogIncarnation(assembly, deployment)
}
