package com.typewritermc.discovery

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.BookDefinition
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.catalog.toWire
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.util.Collections

val TypeDisplayPublicationTest by testSuite {
    test("generated display metadata survives catalog assembly and wire encoding") {
        val expected =
            TypeDisplay(
                name = "Book",
                description = "Authored page collection",
                icon = "material-symbols:book",
                color = "#3F51B5",
            )
        val providers =
            generatedTypeProviders()
                .distinctBy { provider -> provider.definition.id }
        val origin = providerOrigin()
        val assembly =
            CatalogContributions(
                declarations = providers.map { provider -> OwnedTypeDeclaration(origin, provider.definition, provider.display) },
            ).assemble(CatalogAssemblyContext(CatalogGeneration("type display publication")))

        BookDefinition.display shouldBe expected
        assembly.snapshot.types
            .single { published -> published.definition.id == BookDefinition.id }
            .display shouldBe expected

        val wireDisplay =
            assembly.snapshot
                .toWire()
                .types
                .single { published -> published.display?.name == expected.name }
                .display
        wireDisplay?.description shouldBe expected.description
        wireDisplay?.icon shouldBe expected.icon
        wireDisplay?.color shouldBe expected.color
    }
}

private fun generatedTypeProviders(): List<GeneratedTypeProvider> {
    val resources =
        Collections.list(
            requireNotNull(Thread.currentThread().contextClassLoader)
                .getResources(GENERATED_PROVIDER_INDEX_PATH),
        )
    return resources
        .flatMap { resource ->
            resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) }
        }.filter { entry -> entry.kind == GeneratedProviderKind.Type }
        .map { entry ->
            GeneratedProviderInstantiator.PublicZeroArgument
                .instantiate(Class.forName(entry.providerClass)) as GeneratedTypeProvider
        }
}

private fun providerOrigin(): ProviderOrigin =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    ContributionKey(
                        source = ContributionSourceId("test"),
                        sourcePart = "main",
                        producer = ProducerId("test"),
                        name = ContributionName("type_display"),
                    ),
                localIdentity = "type_display",
            ),
        artifact = ArtifactId("test:type_display"),
        sourcePart = "main",
    )
