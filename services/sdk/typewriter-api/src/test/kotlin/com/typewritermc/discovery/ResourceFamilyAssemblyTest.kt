package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.catalog.DeclarationStatus
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

val ResourceFamilyAssemblyTest by testSuite {
    test("keeps disjoint nominal families available") {
        val book = id("Book")
        val tag = id("Tag")

        val assembly = assemble(listOf(record(book), record(tag)), families(book, tag))

        assembly.snapshot.resourceDefinitions.map(AuthoringResourceDefinition::root) shouldContainExactlyInAnyOrder
            listOf(book, tag)
    }

    test("diagnoses a concrete descendant captured by unrelated roots") {
        val left = id("Left")
        val right = id("Right")
        val shared = id("Shared")

        val assembly =
            assemble(
                listOf(
                    record(left, abstract = true),
                    record(right, abstract = true),
                    record(shared, parents = listOf(left, right)),
                ),
                families(left, right),
            )

        assembly.snapshot.resourceDefinitions shouldBe emptyList()
        assembly.snapshot.types.single { it.definition.id == shared }.status.let { status ->
            status is DeclarationStatus.Unavailable &&
                status.reasons.any { it.code == "overlapping_resource_family" }
        } shouldBe true
    }

    test("diagnoses directly nested family roots through their concrete child") {
        val root = id("Root")
        val nested = id("Nested")
        val concrete = id("Concrete")

        val assembly =
            assemble(
                listOf(
                    record(root, abstract = true),
                    record(nested, abstract = true, parents = listOf(root)),
                    record(concrete, parents = listOf(nested)),
                ),
                families(root, nested),
            )

        assembly.snapshot.resourceDefinitions shouldBe emptyList()
    }
}

private fun assemble(
    definitions: List<TypeDefinition>,
    resources: List<AuthoringResourceDefinition>,
): CatalogAssembly =
    CatalogContributions(
        declarations = definitions.map { OwnedTypeDeclaration(origin, it) },
        resources = resources,
    ).assemble(CatalogAssemblyContext(CatalogGeneration("resource families")))

private fun record(
    id: TypeDefinitionId,
    abstract: Boolean = false,
    parents: List<TypeDefinitionId> = emptyList(),
) = TypeDefinition(
    id = id,
    representation = RepresentationTemplate.Record(emptyList(), abstract),
    parents = parents.map(TypeTemplate::Named),
)

private fun families(vararg roots: TypeDefinitionId): List<AuthoringResourceDefinition> =
    roots.mapIndexed { index, root ->
        AuthoringResourceDefinition(ResourceDefinitionId("family.$index"), root)
    }

private fun id(name: String) = TypeDefinitionId(TypeId.Qualified("family", name), 1)

private val origin =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                ContributionKey(
                    ContributionSourceId("test"),
                    "main",
                    ProducerId("sdk"),
                    ContributionName("resource_families"),
                ),
                "resource families",
            ),
        artifact = ArtifactId("test:resource_families"),
        sourcePart = "main",
    )
