package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

private val first = ResourceId("first")
private val second = ResourceId("second")
private val keyframe = ResourceId("keyframe")
private val other = ResourceId("other")

/**
 * Ownership over a catalog whose members are held only by their owner's collection, like keyframes in a segment. They
 * have no inverse field to relink, so their owner candidates and moves go through the owners' own bindings.
 */
val OwnershipRulesTest by testSuite {
    test("a member without a back reference lists every owner whose collection accepts it") {
        withPreparation { preparation, _ ->
            preparation.ownerCandidatesOf(keyframe).toList() shouldBe listOf(first, second)
        }
    }

    test("moving members without a back reference releases them from the old owner and reads current owners") {
        runTest {
            withPreparation { preparation, edit ->
                preparation.move(listOf(keyframe), second, null)
                preparation.ownerOf(keyframe) shouldBe second
                preparation.move(listOf(other), second, null)
                preparation.ownerOf(other) shouldBe second

                val resources = edit.planned()
                resources.getValue(first).children() shouldBe emptyList()
                resources.getValue(second).children() shouldBe listOf(keyframe, other)
            }
        }
    }

    test("the realm root needs no owner even when its type could be owned") {
        val root = ResourceId("root")
        val resources = seed() + (root to AuthoringRecord(TypeSelection.Complete(ROOT_USE), mapOf("frame" to DataValue.StringValue("0"))))
        val catalog = OwnerSideCatalogLease()
        val planner = AuthoringMutationPlanner(catalog.checked, listOf(OWNERSHIP_CONTRACT), listOf(OWNER_BINDING))
        val edit =
            PreparedEdit(
                catalog.generation,
                emptyList(),
                listOf(EditIntent.SetValue(ValueLocation(root, ValuePath(listOf(PathSegment.Field("frame")))), DataValue.StringValue("1"))),
            )

        (planner.plan(resources, edit) is MutationPlanningResult.Accepted) shouldBe true
    }
}

private inline fun withPreparation(body: (RuntimeOperationPreparation, WorkingViewEditContext) -> Unit) {
    val store = InMemoryAuthoringViewStore(OwnerSideCatalogLease(), AuthoringSeed(seed()))
    try {
        store.capture().use { lease ->
            val edit = WorkingViewEditContext(lease.root, "owner-side")
            val invocation = OperationInvocation("owner-side", listOf(keyframe, other))
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
    val items = ((fields.getValue("children") as DataValue.Named).payload as DataValue.ListValue).items
    return items.map { ((it.value as DataValue.Named).payload as DataValue.Link).target.resource }
}

private fun seed() =
    mapOf(
        first to ownerRecord(listOf(keyframe, other)),
        second to ownerRecord(emptyList()),
        keyframe to memberRecord(),
        other to memberRecord(),
    )

private fun ownerRecord(members: List<ResourceId>) =
    AuthoringRecord(
        TypeSelection.Complete(OWNER_USE),
        mapOf(
            "children" to
                DataValue.Named(
                    CHILDREN_USE,
                    DataValue.ListValue(
                        members.mapIndexed { index, member ->
                            ListItem(
                                ItemId("child_$index"),
                                DataValue.Named(CHILD_LINK_USE, DataValue.Link(OWNER_ENDPOINT, LinkTarget(member, null))),
                            )
                        },
                    ),
                ),
        ),
    )

private fun memberRecord() = AuthoringRecord(TypeSelection.Complete(MEMBER_USE), mapOf("frame" to DataValue.StringValue("0")))

private class OwnerSideCatalogLease : AuthoringCatalogLease {
    override val generation = CatalogGeneration("owner_side")
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, DEFINITIONS)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers = EmptyProviders
    override val checks = emptyList<com.typewritermc.discovery.OwnedCheckRecipe>()
    override val relations = listOf(OWNERSHIP_CONTRACT)
    override val endpointBindings = listOf(OWNER_BINDING)
    override val configuration: List<com.typewritermc.configuration.ConfigurationRecipe> = emptyList()
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, ValuePath>()

    override fun retain(): AuthoringCatalogLease = this

    override fun close() = Unit
}

private val OWNER = TypeDefinitionId(TypeId.Qualified("owner_side", "segment"), 1)
private val MEMBER = TypeDefinitionId(TypeId.Qualified("owner_side", "keyframe"), 1)
private val CHILD_LINK = TypeDefinitionId(TypeId.Qualified("owner_side", "keyframe_link"), 1)
private val CHILDREN = TypeDefinitionId(TypeId.Qualified("owner_side", "keyframes"), 1)
private val OWNER_USE = TypeUse.Named(OWNER)
private val MEMBER_USE = TypeUse.Named(MEMBER)
private val ROOT_USE = TypeUse.Named(RealmRootDefinition.id)
private val CHILD_LINK_USE = TypeUse.Named(CHILD_LINK)
private val CHILDREN_USE = TypeUse.Named(CHILDREN)
private val OWNERSHIP = RelationId("segment_keyframes")
private val OWNER_ENDPOINT = EndpointId("segment_keyframes:first")
private val MEMBER_ENDPOINT = EndpointId("segment_keyframes:second")
private val OWNERSHIP_CONTRACT =
    RelationContract(
        OWNERSHIP,
        EndpointDefinition(
            OWNER_ENDPOINT,
            EndpointSlot.First,
            TypeTemplate.Named(OWNER),
            EndpointCardinality.One,
            RelationDeletePolicy.CASCADE,
        ),
        EndpointDefinition(
            MEMBER_ENDPOINT,
            EndpointSlot.Second,
            TypeTemplate.Named(MEMBER),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
        setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)),
    )
private val OWNER_BINDING =
    EndpointBindingTemplate(
        endpoint = OWNER_ENDPOINT,
        containingResource = TypeTemplate.Named(OWNER),
        valueOwner = OWNER,
        relativePath = RelativeFieldPattern(listOf(FieldPatternSegment.Field("children"), FieldPatternSegment.Items)),
        target = TypeTemplate.Named(MEMBER),
        containsCollection = true,
    )
private val DEFINITIONS =
    listOf(
        TypeDefinition(
            OWNER,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(OWNER, "children"), TypeTemplate.Named(CHILDREN))),
                ),
        ),
        TypeDefinition(
            MEMBER,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(MEMBER, "frame"), TypeTemplate.Scalar(ScalarKind.Text))),
                ),
        ),
        TypeDefinition(
            RealmRootDefinition.id,
            representation =
                RepresentationTemplate.Record(
                    listOf(
                        FieldDeclaration(
                            FieldOwner(RealmRootDefinition.id, "frame"),
                            TypeTemplate.Scalar(ScalarKind.Text),
                            overrides = listOf(FieldOwner(MEMBER, "frame")),
                        ),
                    ),
                ),
            parents = listOf(TypeTemplate.Named(MEMBER)),
        ),
        TypeDefinition(CHILD_LINK, representation = RepresentationTemplate.Link(OWNER_ENDPOINT, TypeTemplate.Named(MEMBER))),
        TypeDefinition(CHILDREN, representation = RepresentationTemplate.Sequence(TypeTemplate.Named(CHILD_LINK), CollectionKind.List)),
    )
