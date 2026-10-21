package com.typewritermc.discovery

import com.typewritermc.authoring.PlacementDefinition
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.TagDefinition
import com.typewritermc.types.Color
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.Icon
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.catalog.toWire
import com.typewritermc.types.toWire
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.DeclarationOwner
import java.lang.reflect.Modifier
import java.util.Collections

val TypeDisplayPublicationTest by testSuite {
    test("generated display metadata survives catalog assembly and wire encoding") {
        val expected =
            TypeDisplay(
                name = "Book",
                description = "Authored page collection",
                icon = Icon.Iconify("material-symbols:book"),
                color = Color(0xFF3F51B5u),
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
                .single { published -> published.definition == BookDefinition.declaration }
                .display
        wireDisplay.description shouldBe expected.description
        wireDisplay.icon shouldBe expected.icon.toWire()
        wireDisplay.color.argb shouldBe expected.color.argb.toInt()
    }

    test("a type without a display annotation publishes its class name with the default icon and color") {
        ColorDefinition.display shouldBe
            TypeDisplay(
                name = "Color",
                description = "",
                icon = TypeDisplay.DEFAULT_ICON,
                color = TypeDisplay.DEFAULT_COLOR,
            )
        PlacementDefinition.display.name shouldBe "Placement"
    }

    test("every resource type publishes its search key and other types publish none") {
        val providers = generatedTypeProviders().distinctBy { provider -> provider.definition.id }
        val origin = providerOrigin()
        val published =
            CatalogContributions(
                declarations =
                    providers.map { provider ->
                        OwnedTypeDeclaration(origin, provider.definition, provider.display, searchKey = provider.searchKey)
                    },
            ).assemble(CatalogAssemblyContext(CatalogGeneration("search keys")))
                .snapshot.types
                .associate { it.definition.id to it.searchKey }

        published[BookDefinition.id] shouldBe "book"
        published[PageDefinition.id] shouldBe "page"
        published[TagDefinition.id] shouldBe "tag"
        published[ColorDefinition.id] shouldBe null
    }
}

internal fun generatedTypeProviders(): List<GeneratedTypeProvider> = generatedProviders(GeneratedProviderKind.Type)

/** Instances of every generated provider of [kind] indexed on the test classpath. */
internal fun <T> generatedProviders(kind: GeneratedProviderKind): List<T> {
    val resources =
        Collections.list(
            requireNotNull(Thread.currentThread().contextClassLoader)
                .getResources(GENERATED_PROVIDER_INDEX_PATH),
        )
    return resources
        .flatMap { resource ->
            resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) }
        }.filter { entry -> entry.kind == kind }
        .map { entry ->
            @Suppress("UNCHECKED_CAST")
            instantiateGeneratedProvider(Class.forName(entry.providerClass)) as T
        }
}

private fun instantiateGeneratedProvider(type: Class<*>): Any =
    type.fields
        .singleOrNull { field ->
            field.name == "INSTANCE" && Modifier.isStatic(field.modifiers) && field.type === type
        }?.get(null)
        ?: type.getConstructor().newInstance()

internal fun providerOrigin(): ProviderOrigin =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    contributionKey(
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
