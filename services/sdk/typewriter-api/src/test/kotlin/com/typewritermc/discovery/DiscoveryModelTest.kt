package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val DiscoveryModelTest by testSuite {
    test("identical qualified parent definitions merge across contributions") {
        val definition = abstractDefinition("example", "Parent")
        val assembled =
            TypeContributionAssembler.assemble(
                listOf(
                    contribution("first", definition),
                    contribution("second", definition),
                ),
            )

        assembled.catalog.definitions shouldBe listOf(definition)
    }

    test("conflicting qualified parent definitions fail assembly") {
        val first = abstractDefinition("example", "Parent")
        val second = first.copy(representation = TypeExpression.StringType())

        shouldThrow<IllegalArgumentException> {
            TypeContributionAssembler.assemble(listOf(contribution("first", first), contribution("second", second)))
        }
    }

    test("capability source part eligibility follows the selected engine graph") {
        val capability = ResolvedArtifact(ArtifactId("typewriter:items"), ArtifactVersion("1.2.0"), ArtifactKind.CAPABILITY)
        val engine =
            EngineManifest(
                id = ArtifactId("typewriter:paper"),
                version = ArtifactVersion("1.0.0"),
                hostApi = VersionConstraint("^1"),
                directCapabilities = emptyList(),
                resolvedCapabilities = listOf(capability),
                bundledComponents = listOf(capability),
                contributions = emptyList(),
            )
        val extension =
            ExtensionManifest(
                id = ArtifactId("example:extension"),
                version = ArtifactVersion("1.0.0"),
                sourceParts =
                    listOf(
                        CommonExtensionSourcePart,
                        CapabilityExtensionSourcePart(
                            name = "items",
                            requirements = listOf(ArtifactRequirement(capability.id, VersionConstraint("^1"))),
                            resolved = listOf(capability),
                        ),
                    ),
                buildProvenance = listOf(capability),
                contributions = emptyList(),
            )

        val entries =
            SourcePartEligibilityResolver.resolve(
                DeploymentSelection(engine, setOf(extension.id)),
                listOf(extension),
            )

        entries.map(SourcePartCatalogEntry::eligibility) shouldBe listOf(Eligibility.Eligible, Eligibility.Eligible)
    }

    test("ineligible source parts retain types but cannot contribute executable bindings") {
        val origin = ArtifactId("example:extension")
        val definition = abstractDefinition("example", "Parent")
        val contribution =
            KeyedTypeContribution(
                ContributionKey(origin, "paper", ProducerId("types"), ContributionName("catalog.cbor")),
                TypeDiscoveryContribution(
                    definitions = listOf(definition),
                    prototypeBindings = emptyList(),
                    executableBindings =
                        listOf(
                            ExecutableBinding(
                                "runtime",
                                DiscoveryDomains.Execution,
                                "example.GeneratedModuleProvider",
                            ),
                        ),
                ),
            )

        val assembled =
            TypeContributionAssembler.assemble(
                listOf(contribution),
                listOf(SourcePartCatalogEntry(origin, "paper", Eligibility.Ineligible(listOf("Not selected.")))),
            )

        assembled.catalog.definitions shouldBe listOf(definition)
        assembled.executableBindings shouldBe emptyList()
    }

    test("executable bindings retain their contribution provenance") {
        val key =
            ContributionKey(
                ArtifactId("example:extension"),
                "common",
                ProducerId("types"),
                ContributionName("pages.cbor"),
            )
        val binding = ExecutableBinding("pages", DiscoveryDomains.Realm, "example.GeneratedPageModule")

        val assembled =
            TypeContributionAssembler.assemble(
                listOf(
                    KeyedTypeContribution(
                        key,
                        TypeDiscoveryContribution(
                            definitions = emptyList(),
                            prototypeBindings = emptyList(),
                            executableBindings = listOf(binding),
                        ),
                    ),
                ),
            )

        assembled.executableBindings shouldBe listOf(KeyedExecutableBinding(key, binding))
    }

    test("identical executable bindings from bundled engine core are deduplicated") {
        val panelKey =
            ContributionKey(
                ArtifactId("typewritermc:panel"),
                "main",
                ProducerId("types"),
                ContributionName("core/pages.cbor"),
            )
        val paperKey = panelKey.copy(origin = ArtifactId("typewritermc:paper"))
        val binding = ExecutableBinding("pages", DiscoveryDomains.Realm, "example.GeneratedPageModule")

        val assembled =
            TypeContributionAssembler.assemble(
                listOf(
                    keyedContribution(paperKey, binding),
                    keyedContribution(panelKey, binding),
                ),
            )

        assembled.executableBindings shouldBe listOf(KeyedExecutableBinding(panelKey, binding))
    }

    test("different executable providers with the same identity conflict") {
        val firstKey =
            ContributionKey(
                ArtifactId("example:first"),
                "main",
                ProducerId("types"),
                ContributionName("pages.cbor"),
            )
        val secondKey = firstKey.copy(origin = ArtifactId("example:second"))

        shouldThrow<IllegalArgumentException> {
            TypeContributionAssembler.assemble(
                listOf(
                    keyedContribution(
                        firstKey,
                        ExecutableBinding("pages", DiscoveryDomains.Realm, "example.FirstPageModule"),
                    ),
                    keyedContribution(
                        secondKey,
                        ExecutableBinding("pages", DiscoveryDomains.Realm, "example.SecondPageModule"),
                    ),
                ),
            )
        }
    }
}

private fun keyedContribution(
    key: ContributionKey,
    binding: ExecutableBinding,
) = KeyedTypeContribution(
    key,
    TypeDiscoveryContribution(
        definitions = emptyList(),
        prototypeBindings = emptyList(),
        executableBindings = listOf(binding),
    ),
)

private fun contribution(
    name: String,
    definition: TypeDefinition,
) = KeyedTypeContribution(
    ContributionKey(ArtifactId("example:$name"), "common", ProducerId("types"), ContributionName("catalog.cbor")),
    TypeDiscoveryContribution(
        definitions = listOf(definition),
        prototypeBindings = emptyList(),
        executableBindings = emptyList(),
    ),
)

private fun abstractDefinition(
    namespace: String,
    name: String,
) = TypeDefinition(
    id = ResolvedTypeRef(TypeId.Qualified(namespace, name), 1),
    kind = NominalTypeKind.OPEN_ABSTRACT,
)
