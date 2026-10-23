package com.typewritermc.realm.edit

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.configuration.field
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.EmptyProviders
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.catalog.AuthoringCatalogLease
import com.typewritermc.realm.operation.RuntimeOperationPreparation
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toResourceIds
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

private val first = ResourceId(value = "first")
private val second = ResourceId(value = "second")
private val keyframe = ResourceId(value = "keyframe")
private val other = ResourceId(value = "other")

/**
 * Ownership over a catalog whose members are held only by their owner's collection, like keyframes in a segment. They
 * have no inverse field to relink, so their owner candidates and moves go through the owners' own bindings.
 */
val OwnershipRulesTest by testSuite {
    test("a member without a back reference lists every owner whose collection accepts it") {
        withPreparation { preparation, _ ->
            preparation.ownerCandidatesOf(keyframe.toResourceId()).toList() shouldBe listOf(first, second).toResourceIds()
        }
    }

    test("moving members without a back reference releases them from the old owner and reads current owners") {
        runTest {
            withPreparation { preparation, edit ->
                preparation.move(listOf(keyframe.toResourceId()), second.toResourceId(), null)
                preparation.ownerOf(keyframe.toResourceId()) shouldBe second.toResourceId()
                preparation.move(listOf(other.toResourceId()), second.toResourceId(), null)
                preparation.ownerOf(other.toResourceId()) shouldBe second.toResourceId()

                val resources = edit.planned()
                resources.getValue(first).children() shouldBe emptyList()
                resources.getValue(second).children() shouldBe listOf(keyframe, other)
            }
        }
    }

    test("the realm root needs no owner even when its type could be owned") {
        val root = ResourceId(value = "root")
        val resources =
            seed() +
                (root to AuthoringRecord.of(TypeSelection.CompleteWrapper(ROOT_USE), mapOf("frame" to DataValue.StringValueWrapper("0"))))
        val catalog = OwnerSideCatalogLease()
        val planner = AuthoringMutationPlanner(catalog.checked, listOf(OWNERSHIP_CONTRACT), listOf(OWNER_BINDING))
        val edit =
            PreparedEdit(
                catalog = catalog.generation,
                expectations = emptyList(),
                intents =
                    listOf(
                        EditIntent.createSetValue(
                            at = ValueLocation.of(root, ValuePath.root.field("frame")),
                            value = DataValue.StringValueWrapper("1"),
                        ),
                    ),
            )

        (planner.plan(resources, edit) is MutationPlanningResult.Accepted) shouldBe true
    }
}

private inline fun withPreparation(body: (RuntimeOperationPreparation, WorkingViewEditContext) -> Unit) {
    val store = InMemoryAuthoringViewStore(OwnerSideCatalogLease(), AuthoringSeed(seed()))
    try {
        store.capture().use { lease ->
            val edit = WorkingViewEditContext(lease.root, "owner-side")
            val invocation = OperationInvocation("owner-side", listOf(keyframe, other).toResourceIds())
            body(RuntimeOperationPreparation(invocation, PreparationChoices(), edit), edit)
        }
    } finally {
        store.close()
    }
}

/** The saved resources once the finished edit of this preparation is planned against them. */
private fun WorkingViewEditContext.planned(): Map<ResourceId, AuthoringRecord> {
    val edit = finish()
    val planner = AuthoringMutationPlanner(session.baseline.catalog.checked, listOf(OWNERSHIP_CONTRACT), listOf(OWNER_BINDING))
    val accepted = planner.plan(session.baseline.resources, edit) as MutationPlanningResult.Accepted
    return session.baseline.resources + accepted.plan.resources - accepted.plan.removedResources
}

private fun AuthoringRecord.children(): List<ResourceId> {
    val items = ((fieldMap.getValue("children") as DataValue.NamedWrapper).payload as DataValue.ListValueWrapper).items
    return items.map {
        ((it.value as DataValue.NamedWrapper).payload as DataValue.LinkWrapper)
            .value.target.resource
    }
}

private fun seed() =
    mapOf(
        first to ownerRecord(listOf(keyframe, other)),
        second to ownerRecord(emptyList()),
        keyframe to memberRecord(),
        other to memberRecord(),
    )

private fun ownerRecord(members: List<ResourceId>) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(OWNER_USE),
        mapOf(
            "children" to
                DataValue.named(
                    CHILDREN_USE,
                    DataValue.listValue(
                        members.mapIndexed { index, member ->
                            ListItem(
                                id = ItemId(value = "child_$index"),
                                value =
                                    DataValue.named(
                                        CHILD_LINK_USE,
                                        DataValue.createLink(
                                            endpoint = OWNER_ENDPOINT,
                                            target = LinkTarget(resource = member, opposite = null),
                                        ),
                                    ),
                            )
                        },
                    ),
                ),
        ),
    )

private fun memberRecord() =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(MEMBER_USE),
        mapOf("frame" to DataValue.StringValueWrapper("0")),
    )

private class OwnerSideCatalogLease : AuthoringCatalogLease {
    override val generation = CatalogGeneration(value = "owner_side")
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, DEFINITIONS)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers = EmptyProviders
    override val checks = emptyList<com.typewritermc.discovery.OwnedCheckRecipe>()
    override val relations = listOf(OWNERSHIP_CONTRACT)
    override val endpointBindings = listOf(OWNER_BINDING)
    override val configuration: List<skirout.editor.v1.catalog.ConfigurationRecipe> = emptyList()
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, ValuePath>()

    override fun retain(): AuthoringCatalogLease = this

    override fun close() = Unit
}

private val OWNER = TypeDefinitionId.qualified("owner_side", "segment")
private val MEMBER = TypeDefinitionId.qualified("owner_side", "keyframe")
private val CHILD_LINK = TypeDefinitionId.qualified("owner_side", "keyframe_link")
private val CHILDREN = TypeDefinitionId.qualified("owner_side", "keyframes")
private val OWNER_USE = OWNER.namedUse()
private val MEMBER_USE = MEMBER.namedUse()
private val ROOT_USE = RealmRootDefinition.id.namedUse()
private val CHILD_LINK_USE = CHILD_LINK.namedUse()
private val CHILDREN_USE = CHILDREN.namedUse()
private val OWNERSHIP = RelationId(value = "segment_keyframes")
private val OWNER_ENDPOINT = EndpointId(value = "segment_keyframes:first")
private val MEMBER_ENDPOINT = EndpointId(value = "segment_keyframes:second")
private val OWNERSHIP_CONTRACT =
    RelationContract.of(
        OWNERSHIP,
        EndpointDefinition(
            id = OWNER_ENDPOINT,
            slot = EndpointSlot.FIRST,
            resource = OWNER.namedTemplate(),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CASCADE,
        ),
        EndpointDefinition(
            id = MEMBER_ENDPOINT,
            slot = EndpointSlot.SECOND,
            resource = MEMBER.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
        setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)),
    )
private val OWNER_BINDING =
    EndpointBindingTemplate(
        endpoint = OWNER_ENDPOINT,
        containingResource = OWNER.namedTemplate(),
        valueOwner = OWNER,
        relativePath = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("children"), FieldPatternSegment.ITEMS)),
        target = MEMBER.template(),
        containsCollection = true,
    )
private val DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = OWNER,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = FieldOwner(definition = OWNER, name = "children"), type = CHILDREN.template()),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = MEMBER,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = MEMBER, name = "frame"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = RealmRootDefinition.id,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = RealmRootDefinition.id, name = "frame"),
                                type = ScalarKind.TEXT.template,
                                overrides = listOf(FieldOwner(definition = MEMBER, name = "frame")),
                            ),
                        ),
                    abstract_ = false,
                ),
            parents = listOf(MEMBER.namedTemplate()),
        ),
        TypeDefinition.partial(
            id = CHILD_LINK,
            representation = RepresentationTemplate.createLink(endpoint = OWNER_ENDPOINT, target = MEMBER.template()),
        ),
        TypeDefinition.partial(
            id = CHILDREN,
            representation = RepresentationTemplate.createSequence(item = CHILD_LINK.template(), kind = CollectionKind.LIST),
        ),
    )
