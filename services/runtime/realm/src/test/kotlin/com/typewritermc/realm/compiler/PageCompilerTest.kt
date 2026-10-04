package com.typewritermc.realm.compiler

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.engine.CompiledEdgeOrigin
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.SnapshotCatalogLease
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.realm.checking.tokensFor
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
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
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
import java.util.concurrent.atomic.AtomicInteger

private val pageId = ResourceId("page")
private val childId = ResourceId("child")
private val missingId = ResourceId("missing")

val PageCompilerTest by testSuite {
    test("one sided ownership links compile the complete owned shard") {
        fixture(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("first"))).use { captured ->
            val result = compiler().compile(pageId, captured.root)

            result as PageCompileResult.Success
            result.shard.resources
                .map { it.key.source }
                .toSet() shouldBe setOf(pageId, childId)
            result.shard.edges.single().let { edge ->
                edge.source.source shouldBe pageId
                edge.target.source shouldBe childId
                (edge.origin as CompiledEdgeOrigin.Relation).relation shouldBe OWNERSHIP
            }
        }
    }

    test("authored content changes produce a new shard identity") {
        val first = fixture(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("first")))
        val second = fixture(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("second")), "snapshot_2")
        try {
            val firstResult = compiler().compile(pageId, first.root) as PageCompileResult.Success
            val secondResult = compiler().compile(pageId, second.root) as PageCompileResult.Success

            (secondResult.shard.inputFingerprint == firstResult.shard.inputFingerprint) shouldBe false
            (secondResult.shard.digest == firstResult.shard.digest) shouldBe false
        } finally {
            first.close()
            second.close()
        }
    }

    test("missing owned resources block publication") {
        fixture(mapOf(pageId to pageRecord(listOf(missingId)))).use { captured ->
            val result = compiler().compile(pageId, captured.root)

            result as PageCompileResult.Blocked
            result.diagnostics.single().code shouldBe "missing_owned_resource"
        }
    }

    test("parallel occurrences retain distinct endpoint locations") {
        fixture(mapOf(pageId to pageRecord(listOf(childId, childId)), childId to childRecord("child"))).use { captured ->
            val result = compiler().compile(pageId, captured.root) as PageCompileResult.Success

            result.shard.edges.size shouldBe 2
            result.shard.edges
                .map { (it.origin as CompiledEdgeOrigin.Relation).firstLocation }
                .distinct()
                .size shouldBe 2
        }
    }

    test("capturedUnavailableResourceBlocksCompilationWhileRetainingItsDefinitionIdentity") {
        val unavailableType = TypeDefinitionId(TypeId.Qualified("removed", "page"), 1)
        val unavailable =
            AuthoringRecord(
                TypeSelection.Complete(TypeUse.Named(unavailableType)),
                mapOf("legacy" to DataValue.StringValue("preserved")),
            )
        fixture(
            resources = mapOf(pageId to unavailable),
            resourceDefinitions = mapOf(pageId to ResourceDefinitionId("page")),
        ).use { captured ->
            val result = compiler().compile(pageId, captured.root) as PageCompileResult.Blocked

            result.diagnostics.map { it.code }.toSet() shouldBe
                setOf("unavailable_resource_type", "missing_native_binding_evidence")
            captured.root.resourceDefinitions[pageId] shouldBe ResourceDefinitionId("page")
        }
    }
}

private fun compiler() =
    PageCompiler(
        ownershipRelations = setOf(OWNERSHIP),
        bindings =
            mapOf(
                PAGE_USE to NativeBindingRequirement(PAGE_USE, com.typewritermc.authoring.NativeBindingId("page"), "page_signature"),
                CHILD_USE to NativeBindingRequirement(CHILD_USE, com.typewritermc.authoring.NativeBindingId("child"), "child_signature"),
            ),
    )

private fun fixture(
    resources: Map<ResourceId, AuthoringRecord>,
    snapshot: String = "snapshot_1",
    resourceDefinitions: Map<ResourceId, ResourceDefinitionId> = emptyMap(),
): com.typewritermc.realm.authoring.SnapshotLease {
    val catalog = CompilerCatalogLease()
    val store =
        InMemoryAuthoringSnapshotStore(
            catalog,
            AuthoredSnapshotSeed(
                SnapshotId(snapshot),
                resources,
                tokensFor(resources, catalog.generation),
                resourceDefinitions,
            ),
        )
    val captured = store.capture()
    store.close()
    return captured
}

private fun pageRecord(targets: List<ResourceId>) =
    AuthoringRecord(
        TypeSelection.Complete(PAGE_USE),
        mapOf(
            "children" to
                DataValue.Named(
                    CHILDREN_USE,
                    DataValue.ListValue(
                        targets.mapIndexed { index, target ->
                            ListItem(
                                ItemId("child_$index"),
                                DataValue.Named(CHILD_LINK_USE, DataValue.Link(PAGE_ENDPOINT, LinkTarget(target, null))),
                            )
                        },
                    ),
                ),
        ),
    )

private fun childRecord(value: String) =
    AuthoringRecord(
        TypeSelection.Complete(CHILD_USE),
        mapOf("value" to DataValue.StringValue(value)),
    )

private class CompilerCatalogLease private constructor(
    private val references: AtomicInteger,
) : SnapshotCatalogLease {
    constructor() : this(AtomicInteger(1))

    override val generation = CatalogGeneration("compiler_catalog")
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, DEFINITIONS)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers = EmptyProviders
    override val checks = emptyList<com.typewritermc.discovery.OwnedCheckRecipe>()
    override val relations = listOf(OWNERSHIP_CONTRACT)
    override val endpointBindings = listOf(PAGE_BINDING)
    override val resources =
        listOf(
            AuthoringResourceDefinition(ResourceDefinitionId("page"), PAGE),
            AuthoringResourceDefinition(ResourceDefinitionId("child"), CHILD),
        )

    override fun retain(): SnapshotCatalogLease {
        references.incrementAndGet()
        return CompilerCatalogLease(references)
    }

    override fun close() {
        check(references.decrementAndGet() >= 0)
    }
}

private val PAGE = TypeDefinitionId(TypeId.Qualified("compiler", "page"), 1)
private val CHILD = TypeDefinitionId(TypeId.Qualified("compiler", "child"), 1)
private val CHILD_LINK = TypeDefinitionId(TypeId.Qualified("compiler", "child_link"), 1)
private val CHILDREN = TypeDefinitionId(TypeId.Qualified("compiler", "children"), 1)
private val PAGE_USE = TypeUse.Named(PAGE)
private val CHILD_USE = TypeUse.Named(CHILD)
private val CHILD_LINK_USE = TypeUse.Named(CHILD_LINK)
private val CHILDREN_USE = TypeUse.Named(CHILDREN)
private val OWNERSHIP = RelationId("page_children")
private val PAGE_ENDPOINT = EndpointId("page_children:first")
private val CHILD_ENDPOINT = EndpointId("page_children:second")
private val OWNERSHIP_CONTRACT =
    RelationContract(
        OWNERSHIP,
        EndpointDefinition(
            PAGE_ENDPOINT,
            EndpointSlot.First,
            TypeTemplate.Named(PAGE),
            EndpointCardinality.One,
            RelationDeletePolicy.CASCADE,
        ),
        EndpointDefinition(
            CHILD_ENDPOINT,
            EndpointSlot.Second,
            TypeTemplate.Named(CHILD),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
    )
private val PAGE_BINDING =
    EndpointBindingTemplate(
        endpoint = PAGE_ENDPOINT,
        containingResource = TypeTemplate.Named(PAGE),
        valueOwner = PAGE,
        relativePath = RelativeFieldPattern(listOf(FieldPatternSegment.Field("children"), FieldPatternSegment.Items)),
        target = TypeTemplate.Named(CHILD),
        containsCollection = true,
    )
private val DEFINITIONS =
    listOf(
        TypeDefinition(
            PAGE,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(PAGE, "children"), TypeTemplate.Named(CHILDREN))),
                ),
        ),
        TypeDefinition(
            CHILD,
            representation =
                RepresentationTemplate.Record(
                    listOf(FieldDeclaration(FieldOwner(CHILD, "value"), TypeTemplate.Scalar(ScalarKind.Text))),
                ),
        ),
        TypeDefinition(
            CHILD_LINK,
            representation = RepresentationTemplate.Link(PAGE_ENDPOINT, TypeTemplate.Named(CHILD)),
        ),
        TypeDefinition(
            CHILDREN,
            representation = RepresentationTemplate.Sequence(TypeTemplate.Named(CHILD_LINK), CollectionKind.List),
        ),
    )
