package com.typewritermc.realm.authoring

import com.typewritermc.authoring.of
import com.typewritermc.realm.search.ownershipClosure
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.testkit.definitions
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.endpointId
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId

private val NODE = TypeDefinitionId.qualified("test", "node")
private val OWNERSHIP = RelationId(value = "ownership")
private val RELATED = RelationId(value = "related")

/** A node owns another through `owned` and refers to another through `related`, a relation outside ownership. */
private val catalog =
    DefinitionCatalog(
        definitions {
            record(NODE) {
                field("owned", TypeDefinitionId.qualified("test", "owned_link").template())
                field("related", TypeDefinitionId.qualified("test", "related_link").template())
            }
            link(TypeDefinitionId.qualified("test", "owned_link"), OWNERSHIP.endpointId(EndpointSlot.FIRST), NODE.template())
            link(TypeDefinitionId.qualified("test", "related_link"), RELATED.endpointId(EndpointSlot.FIRST), NODE.template())
        },
        relations =
            listOf(
                contract(OWNERSHIP, setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID))),
                contract(RELATED, emptySet()),
            ),
    )

val OwnershipClosureTest by testSuite {
    test("the ownership closure of a resource holds its owned descendants, ends at a cycle and leaves out other relations") {
        val root = ResourceId(value = "root")
        val child = ResourceId(value = "child")
        val grandchild = ResourceId(value = "grandchild")
        val outside = ResourceId(value = "outside")
        val resources =
            mapOf(
                root to node("owned" to link(OWNERSHIP, child), "related" to link(RELATED, outside)),
                child to node("owned" to link(OWNERSHIP, grandchild)),
                grandchild to node("owned" to link(OWNERSHIP, root)),
                outside to node(),
            )
        catalog.lease().use { lease ->
            val view = AuthoringView(lease, resources, ResourceValueMapper.discover(resources).associateBy { it.id })

            view.ownershipClosure(setOf(root)) shouldBe setOf(root, child, grandchild)
        }
    }
}

private fun contract(
    id: RelationId,
    families: Set<RelationFamilyId>,
) = RelationContract.of(
    id,
    EndpointDefinition(
        id = id.endpointId(EndpointSlot.FIRST),
        slot = EndpointSlot.FIRST,
        resource = NODE.namedTemplate(),
        cardinality = EndpointCardinality.ONE,
        onDelete = RelationDeletePolicy.CLEAR,
    ),
    EndpointDefinition(
        id = id.endpointId(EndpointSlot.SECOND),
        slot = EndpointSlot.SECOND,
        resource = NODE.namedTemplate(),
        cardinality = EndpointCardinality.ONE,
        onDelete = RelationDeletePolicy.CLEAR,
    ),
    families,
)

private fun node(vararg fields: Pair<String, DataValue>) =
    AuthoringRecord.of(TypeSelection.CompleteWrapper(NODE.namedUse()), fields.toMap())

private fun link(
    relation: RelationId,
    target: ResourceId,
) = DataValue.createLink(endpoint = relation.endpointId(EndpointSlot.FIRST), target = LinkTarget(resource = target, opposite = null))
