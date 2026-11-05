package com.typewritermc.discovery

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.testkit.recordType
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
    test("reserved read identities cannot replace intrinsic schemas or isolate unrelated declarations") {
        val reserved = TypeDefinitionId.qualified(com.typewritermc.expression.CANONICAL_READ_NAMESPACE, "UnfamiliarModel")
        val healthy = TypeDefinitionId.qualified("structure", "Healthy")
        val assembly = assemble(listOf(recordType(reserved), recordType(healthy)))
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
        val loose = TypeDefinitionId.qualified("structure", "Loose")
        val owned = TypeDefinitionId.qualified("structure", "Owned")

        val assembly =
            assemble(
                structure() + listOf(resource(loose), resource(owned)),
                listOf(sectionsRelation, ownership("section.owned", section, owned)),
            )

        assembly.checked.definition(loose).codes() shouldBe setOf("unowned_resource_type")
        assembly.checked.definition(owned) shouldBe DeclarationStatus.READY
    }

    test("an owned abstract member owns its concrete descendants and plain values need no owner") {
        val member = TypeDefinitionId.qualified("structure", "Member")
        val concrete = TypeDefinitionId.qualified("structure", "Concrete")
        val value = TypeDefinitionId.qualified("structure", "Value")

        val assembly =
            assemble(
                structure() +
                    listOf(
                        resource(member, abstract = true),
                        resource(concrete, parents = listOf(member)),
                        OwnedTypeDeclaration(origin, recordType(value)),
                    ),
                listOf(sectionsRelation, ownership("section.members", section, member)),
            )

        assembly.checked.definition(concrete) shouldBe DeclarationStatus.READY
        assembly.checked.definition(value) shouldBe DeclarationStatus.READY
    }

    test("rejects a generic realm section type") {
        val generic = TypeDefinitionId.qualified("structure", "GenericSection")
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
