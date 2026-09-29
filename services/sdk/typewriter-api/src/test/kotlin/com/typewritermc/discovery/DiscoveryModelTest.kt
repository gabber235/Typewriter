package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.elements.Cue
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ProducerId
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.library.CoreResourceDefinitionIds
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val DiscoveryModelTest by testSuite {
    test("core resource declarations carry their complete schema roots without dependency codecs") {
        val contributions =
            CoreResourceDefinitionIds::class.java.classLoader
                .getResources("META-INF/typewriter/contributions/types/declared.cbor")
                .toList()
                .map { resource -> resource.openStream().use { TypeDiscoveryContributionCodec.decode(it.readAllBytes()) } }
        val core = contributions.single { contribution ->
            contribution.resourceDefinitions.any { it.id == CoreResourceDefinitionIds.CUE }
        }
        val cue = core.resourceDefinitions.single { it.id == CoreResourceDefinitionIds.CUE }
        val root = (cue.acceptedRoot as TypeExpression.Named).reference

        core.definitions.any { it.id == root && it.qualifiedName == Cue::class.qualifiedName } shouldBe true
        core.prototypeBindings.any { it.type == root } shouldBe false
        core.resourceDefinitions.map { it.id }.toSet() shouldBe setOf(
            CoreResourceDefinitionIds.BOOK,
            CoreResourceDefinitionIds.TAG,
            CoreResourceDefinitionIds.PAGE,
            CoreResourceDefinitionIds.ELEMENT,
            CoreResourceDefinitionIds.CUE,
        )
    }

    test("identical qualified parent definitions merge across contributions") {
        val definition = abstractDefinition("example", "Parent")
        val assembled =
            TypeContributionAssembler.assemble(
                listOf(
                    contribution("first", definition),
                    contribution("second", definition),
                ),
            )

        assembled.catalog.definitions.single { it.id == definition.id } shouldBe definition
    }

    test("a shared abstract dependency needs no synthetic author") {
        val dependency = abstractDefinition("shared", "Cue")
        val assembled = TypeContributionAssembler.assemble(listOf(contribution("extension", dependency)))

        assembled.requireType(dependency.id).definition shouldBe dependency
        assembled.requireType(dependency.id).canCreate(DiscoveryDomains.Realm) shouldBe false
    }

    test("a sealed dependency is a valid structural description") {
        val dependency = abstractDefinition("shared", "Cue").copy(kind = NominalTypeKind.SEALED_ABSTRACT)

        val assembled = TypeContributionAssembler.assemble(listOf(contribution("extension", dependency)))
        assembled.requireType(dependency.id).definition shouldBe dependency
    }

    test("each contribution carries the complete ancestry of a descendant") {
        val parent = abstractDefinition("shared", "Parent").copy(kind = NominalTypeKind.SEALED_ABSTRACT)
        val middle = abstractDefinition("shared", "Middle").copy(parents = listOf(parent.id))
        val child = TypeDefinition(
            id = ResolvedTypeRef(TypeId.Qualified("extension", "Child"), 1),
            kind = NominalTypeKind.CONCRETE,
            parents = listOf(middle.id),
        )
        val parentContribution = contribution("shared", parent)
        val middleContribution = contribution("shared", middle, parent).copy(
            key = parentContribution.key.copy(name = ContributionName("middle.cbor")),
        )
        val childContribution = contribution("extension", child, middle, parent)

        val assembled = TypeContributionAssembler.assemble(listOf(parentContribution, middleContribution, childContribution))
        assembled.requireType(child.id).definition shouldBe child
    }

    test("a declared type keeps its published display name when another graph references it") {
        val referenced =
            TypeDefinition(
                id =
                    ResolvedTypeRef(
                        TypeId.Declared(
                            com.typewritermc.types.DeclaredTypeId
                                .parse("019d3a87005070008000000000000050"),
                        ),
                        1,
                    ),
                kind = NominalTypeKind.CONCRETE,
            )
        val published = referenced.copy(displayName = "Shared Book")
        val assembled =
            TypeContributionAssembler.assemble(
                listOf(contribution("first", referenced), contribution("second", published)),
            )

        assembled.catalog.definitions
            .single { it.id == referenced.id }
            .displayName shouldBe "Shared Book"
    }

    test("conflicting qualified parent definitions fail assembly") {
        val first = abstractDefinition("example", "Parent")
        val second = first.copy(representation = TypeExpression.StringType())

        shouldThrow<IllegalArgumentException> {
            TypeContributionAssembler.assemble(listOf(contribution("first", first), contribution("second", second)))
        }
    }

    test("each contribution must carry its own dependency closure") {
        val parent = abstractDefinition("shared", "Parent")
        val child = abstractDefinition("example", "Child").copy(parents = listOf(parent.id))

        shouldThrow<IllegalArgumentException> {
            TypeContributionAssembler.assemble(listOf(contribution("shared", parent), contribution("extension", child)))
        }.message?.contains("missing exact type") shouldBe true
    }

    test("resource definitions with the same id must agree") {
        val first = abstractDefinition("shared", "First")
        val second = abstractDefinition("shared", "Second")
        val id = com.typewritermc.authoring.ResourceDefinitionId("example.resource")
        val one = contribution("first", first).copy(
            contribution = TypeDiscoveryContribution(
                definitions = listOf(first),
                prototypeBindings = emptyList(),
                executableBindings = emptyList(),
                resourceDefinitions = listOf(AuthoringResourceDefinition(id, TypeExpression.Named(first.id))),
            ),
        )
        val two = contribution("second", second).copy(
            contribution = TypeDiscoveryContribution(
                definitions = listOf(second),
                prototypeBindings = emptyList(),
                executableBindings = emptyList(),
                resourceDefinitions = listOf(AuthoringResourceDefinition(id, TypeExpression.Named(second.id))),
            ),
        )

        shouldThrow<IllegalArgumentException> {
            TypeContributionAssembler.assemble(listOf(one, two))
        }.message?.contains("Conflicting resource definition") shouldBe true
    }

    test("active concrete type with a renamed inherited field fails staging") {
        val parent =
            abstractDefinition("example", "Page").copy(
                representation = TypeExpression.Record(listOf(TypeField("name", TypeExpression.StringType()))),
            )
        val concrete =
            TypeDefinition(
                id = ResolvedTypeRef(TypeId.Qualified("example", "BrokenPage"), 1),
                kind = NominalTypeKind.CONCRETE,
                parents = listOf(parent.id),
                representation = TypeExpression.Record(listOf(TypeField("display_name", TypeExpression.StringType()))),
            )
        val origin = ArtifactId("example:extension")
        val contribution =
            keyed(
                ContributionKey(origin.source(), "common", ProducerId("types"), ContributionName("declared.cbor")),
                TypeDiscoveryContribution(
                    definitions = listOf(parent, concrete),
                    prototypeBindings =
                        listOf(
                            PrototypeBinding(
                                concrete.id,
                                "example.BrokenPage",
                                "example.BrokenPagePrototype",
                                setOf(DiscoveryDomains.Realm),
                            ),
                        ),
                    executableBindings = emptyList(),
                ),
            )

        val failure =
            shouldThrow<IllegalArgumentException> {
                TypeContributionAssembler.assemble(listOf(contribution))
            }
        failure.message?.contains("Page") shouldBe true
        failure.message?.contains("name") shouldBe true

        val inactive =
            TypeContributionAssembler.assemble(
                listOf(contribution),
                listOf(SourcePartCatalogEntry(origin, "common", Eligibility.Ineligible(listOf("Not selected.")))),
            )
        inactive.prototypeBindings shouldBe emptyList()
    }

    test("capability source part eligibility follows the selected engine graph") {
        val capability = ResolvedArtifact(ArtifactId("typewriter:items"), ArtifactVersion("1.2.0"), ArtifactKind.CAPABILITY)
        val engine =
            EngineManifest(
                id = ArtifactId("typewriter:paper"),
                version = ArtifactVersion("1.0.0"),
                hostApi = VersionConstraint("^1"),
                runtimeEntrypointClass = "example.EngineEntrypoint",
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
            keyed(
                ContributionKey(origin.source(), "paper", ProducerId("types"), ContributionName("catalog.cbor")),
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

        assembled.catalog.definitions.single { it.id == definition.id } shouldBe definition
        assembled.executableBindings shouldBe emptyList()
    }

    test("known ineligible metadata remains visible with its source reason") {
        val origin = ArtifactId("example:extension")
        val definition =
            TypeDefinition(
                id = ResolvedTypeRef(TypeId.Qualified("example", "Entry"), 1),
                kind = NominalTypeKind.CONCRETE,
            )
        val contribution =
            keyed(
                ContributionKey(origin.source(), "paper", ProducerId("types"), ContributionName("declared.cbor")),
                TypeDiscoveryContribution(
                    definitions = listOf(definition),
                    prototypeBindings = emptyList(),
                    executableBindings = emptyList(),
                    metadata = listOf(TypeMetadata(definition.id)),
                ),
            )
        val assembled =
            TypeContributionAssembler.assemble(
                listOf(contribution),
                listOf(SourcePartCatalogEntry(origin, "paper", Eligibility.Ineligible(listOf("Not selected.")))),
            )
        assembled.requireType(definition.id).carrierEligibility[origin] shouldBe Eligibility.Ineligible(listOf("Not selected."))
        assembled.prototypeBindings shouldBe emptyList()
    }

    test("metadata without its exact definition fails before publication") {
        val missing = ResolvedTypeRef(TypeId.Qualified("example", "Missing"), 1)
        val failure =
            shouldThrow<IllegalArgumentException> {
                TypeDiscoveryContribution(
                    definitions = emptyList(),
                    prototypeBindings = emptyList(),
                    executableBindings = emptyList(),
                    metadata = listOf(TypeMetadata(missing)),
                )
            }
        failure.message?.contains("metadata entry") shouldBe true
    }

    test("metadata whose schema closure is incomplete fails before publication") {
        val missing = ResolvedTypeRef(TypeId.Qualified("example", "MissingParent"), 1)
        val child =
            TypeDefinition(
                id = ResolvedTypeRef(TypeId.Qualified("example", "Child"), 1),
                kind = NominalTypeKind.CONCRETE,
                parents = listOf(missing),
            )
        val contribution =
            keyed(
                ContributionKey(ArtifactId("example:extension").source(), "common", ProducerId("types"), ContributionName("declared.cbor")),
                TypeDiscoveryContribution(
                    definitions = listOf(child),
                    prototypeBindings = emptyList(),
                    executableBindings = emptyList(),
                    metadata = listOf(TypeMetadata(child.id)),
                ),
            )

        val failure =
            shouldThrow<IllegalArgumentException> {
                TypeContributionAssembler.assemble(listOf(contribution))
            }
        failure.message?.contains("MissingParent") shouldBe true
    }

    test("executable bindings retain their contribution provenance") {
        val key =
            ContributionKey(
                ArtifactId("example:extension").source(),
                "common",
                ProducerId("types"),
                ContributionName("pages.cbor"),
            )
        val binding = ExecutableBinding("pages", DiscoveryDomains.Realm, "example.GeneratedPageModule")

        val assembled =
            TypeContributionAssembler.assemble(
                listOf(
                    keyed(
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
                ArtifactId("typewritermc:panel").source(),
                "main",
                ProducerId("types"),
                ContributionName("core/pages.cbor"),
            )
        val paperKey = panelKey.copy(source = ArtifactId("typewritermc:paper").source())
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
                ArtifactId("example:first").source(),
                "main",
                ProducerId("types"),
                ContributionName("pages.cbor"),
            )
        val secondKey = firstKey.copy(source = ArtifactId("example:second").source())

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
) = keyed(
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
    vararg dependencies: TypeDefinition,
) = keyed(
    ContributionKey(ArtifactId("example:$name").source(), "common", ProducerId("types"), ContributionName("catalog.cbor")),
    TypeDiscoveryContribution(
        definitions = listOf(definition) + dependencies,
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

private fun ArtifactId.source(): ContributionSourceId = ContributionSourceId("artifact:$value")

private fun keyed(key: ContributionKey, contribution: TypeDiscoveryContribution): KeyedTypeContribution =
    KeyedTypeContribution(key, setOf(ArtifactId(key.source.value.removePrefix("artifact:"))), contribution)
