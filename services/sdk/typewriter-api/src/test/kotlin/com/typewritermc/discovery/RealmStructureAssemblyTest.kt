package com.typewritermc.discovery

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.catalog.reasons
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RESOURCE_OWNERSHIP_FAMILY
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

val RealmStructureAssemblyTest by testSuite {
    test("the ownership family annotation id is the editor contract's ownership family") {
        RESOURCE_OWNERSHIP_FAMILY_ID shouldBe RESOURCE_OWNERSHIP_FAMILY.value
    }

    test("reserved read identities cannot replace intrinsic schemas or isolate unrelated declarations") {
        val reserved = TypeDefinitionId.qualified(com.typewritermc.expression.CANONICAL_READ_NAMESPACE, "UnfamiliarModel")
        val healthy = id("Healthy")
        val assembly = assemble(listOf(record(reserved), record(healthy)))
        assembly.checked.definition(reserved).codes() shouldBe setOf("reserved_intrinsic_type_identity")
        assembly.checked.definition(healthy) shouldBe DeclarationStatus.READY
    }

    test("publishes the realm root type and keeps the root available without an owner") {
        val assembly = assemble(structure())

        assembly.editorCatalog.realmRoot shouldBe RealmRootDefinition.id
        assembly.checked.definition(RealmRootDefinition.id) shouldBe DeclarationStatus.READY
        assembly.checked.definition(section) shouldBe DeclarationStatus.READY
    }

    test("rejects a concrete resource type that no ownership relation owns") {
        val loose = id("Loose")
        val owned = id("Owned")

        val assembly =
            assemble(
                structure() + listOf(resource(loose), resource(owned)),
                listOf(sectionsRelation, ownership("section.owned", section, owned)),
            )

        assembly.checked.definition(loose).codes() shouldBe setOf("unowned_resource_type")
        assembly.checked.definition(owned) shouldBe DeclarationStatus.READY
    }

    test("an owned abstract member owns its concrete descendants and plain values need no owner") {
        val member = id("Member")
        val concrete = id("Concrete")
        val value = id("Value")

        val assembly =
            assemble(
                structure() +
                    listOf(
                        resource(member, abstract = true),
                        resource(concrete, parents = listOf(member)),
                        OwnedTypeDeclaration(origin, record(value)),
                    ),
                listOf(sectionsRelation, ownership("section.members", section, member)),
            )

        assembly.checked.definition(concrete) shouldBe DeclarationStatus.READY
        assembly.checked.definition(value) shouldBe DeclarationStatus.READY
    }

    test("rejects a generic realm section type") {
        val generic = id("GenericSection")
        val declaration =
            TypeDefinition(
                id = generic,
                parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = generic, index = 0), name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(RealmSectionDefinition.id.namedTemplate()),
            )

        val assembly = assemble(structure() + OwnedTypeDeclaration(origin, declaration, searchKey = "generic"))

        assembly.checked.definition(generic).codes() shouldBe setOf("generic_realm_section")
    }
}

private val section = id("Section")

private val sectionsRelation = ownership("realm.sections", RealmRootDefinition.id, RealmSectionDefinition.id)

/** The realm root, the section contract, and one concrete section owned through the sections relation. */
private fun structure(): List<OwnedTypeDeclaration> =
    listOf(
        resource(RealmRootDefinition.id),
        resource(RealmSectionDefinition.id, abstract = true),
        resource(section, parents = listOf(RealmSectionDefinition.id)),
    )

private fun assemble(
    declarations: List<OwnedTypeDeclaration>,
    relations: List<RelationContract> = listOf(sectionsRelation),
): CatalogAssembly =
    CatalogContributions(declarations = declarations, relations = relations)
        .assemble(CatalogAssemblyContext(CatalogGeneration(value = "realm structure")))

@JvmName("assembleDefinitions")
private fun assemble(definitions: List<TypeDefinition>): CatalogAssembly = assemble(definitions.map { OwnedTypeDeclaration(origin, it) })

private fun resource(
    id: TypeDefinitionId,
    abstract: Boolean = false,
    parents: List<TypeDefinitionId> = emptyList(),
) = OwnedTypeDeclaration(origin, record(id, abstract, parents), searchKey = id.toString().filter(Char::isLetter).lowercase())

private fun record(
    id: TypeDefinitionId,
    abstract: Boolean = false,
    parents: List<TypeDefinitionId> = emptyList(),
) = TypeDefinition.partial(
    id = id,
    representation =
        RepresentationTemplate.createRecord(
            fields = emptyList(),
            abstract_ = abstract,
        ),
    parents =
        parents.map {
            it.namedTemplate()
        },
)

private fun ownership(
    relation: String,
    owner: TypeDefinitionId,
    member: TypeDefinitionId,
) = RelationContract.of(
    id = RelationId(value = relation),
    first =
        EndpointDefinition(
            id = EndpointId(value = "$relation:first"),
            slot = EndpointSlot.FIRST,
            resource = owner.namedTemplate(),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CASCADE,
        ),
    second =
        EndpointDefinition(
            id = EndpointId(value = "$relation:second"),
            slot = EndpointSlot.SECOND,
            resource = member.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
    families = setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)),
)

private fun DeclarationStatus.codes(): Set<String> =
    (this as? DeclarationStatus.UnavailableWrapper)?.reasons.orEmpty().mapTo(linkedSetOf()) {
        it.code
    }

private fun id(name: String) = TypeDefinitionId.qualified("structure", name)

private val origin =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    contributionKey(
                        ContributionSourceId("test"),
                        "main",
                        ProducerId("sdk"),
                        ContributionName("realm_structure"),
                    ),
                localIdentity = "realm structure",
            ),
        artifact = ArtifactId("test:realm_structure"),
        sourcePart = "main",
    )
