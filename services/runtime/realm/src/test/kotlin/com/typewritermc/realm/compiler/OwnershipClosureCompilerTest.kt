package com.typewritermc.realm.compiler

import com.typewritermc.authoring.CompilationUnitDefinition
import com.typewritermc.authoring.of
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.engine.ResourceGraphCompileResult
import com.typewritermc.engine.relation
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.EmptyProviders
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compiled_content.CompiledEdgeOrigin
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValuePath
import java.util.concurrent.atomic.AtomicInteger

private val pageId = ResourceId("page")
private val childId = ResourceId("child")
private val missingId = ResourceId("missing")

val OwnershipClosureCompilerTest by testSuite {
    test("one sided ownership links compile the complete owned shard") {
        fixture(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("first"))).use { captured ->
            val result = with(captured.root) { compiler(captured.root).compile(pageId) }

            result as ResourceGraphCompileResult.Success
            result.shard.facts.resources
                .map { it.key.source.toResourceId() }
                .toSet() shouldBe setOf(pageId, childId)
            result.shard.facts.edges.single().let { edge ->
                edge.source.source shouldBe pageId.toSkir()
                edge.target.source shouldBe childId.toSkir()
                edge.relation shouldBe OWNERSHIP
            }
        }
    }

    test("authored content changes produce a new shard identity") {
        val first = fixture(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("first")))
        val second = fixture(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("second")), "snapshot_2")
        try {
            val firstResult = with(first.root) { compiler(first.root).compile(pageId) } as ResourceGraphCompileResult.Success
            val secondResult = with(second.root) { compiler(second.root).compile(pageId) } as ResourceGraphCompileResult.Success

            (secondResult.inputFingerprint == firstResult.inputFingerprint) shouldBe false
            (secondResult.shard.digest == firstResult.shard.digest) shouldBe false
        } finally {
            first.close()
            second.close()
        }
    }

    test("a nested compilation unit is its own shard, not part of its owner's") {
        val nested = ResourceId("nested")
        val records = mapOf(pageId to pageRecord(listOf(childId, nested)), childId to childRecord("first"), nested to nestedRecord())
        fixture(records).use { captured ->
            val compiler = compiler(captured.root)
            val page = with(captured.root) { compiler.compile(pageId) } as ResourceGraphCompileResult.Success
            val unit = with(captured.root) { compiler.compile(nested) } as ResourceGraphCompileResult.Success

            page.shard.facts.resources
                .map { it.key.source.toResourceId() }
                .toSet() shouldBe setOf(pageId, childId)
            page.shard.facts.edges
                .map { it.target.source.toResourceId() }
                .toSet() shouldBe setOf(childId, nested)
            unit.shard.facts.resources
                .map { it.key.source.toResourceId() } shouldBe listOf(nested)
        }
    }

    test("missing owned resources block publication") {
        fixture(mapOf(pageId to pageRecord(listOf(missingId)))).use { captured ->
            val result = with(captured.root) { compiler(captured.root).compile(pageId) }

            result as ResourceGraphCompileResult.Blocked
            result.diagnostics.single().code shouldBe "missing_owned_resource"
        }
    }

    test("parallel occurrences retain distinct endpoint locations") {
        fixture(mapOf(pageId to pageRecord(listOf(childId, childId)), childId to childRecord("child"))).use { captured ->
            val result = with(captured.root) { compiler(captured.root).compile(pageId) } as ResourceGraphCompileResult.Success

            result.shard.facts.edges.size shouldBe 2
            result.shard.facts.edges
                .map { (it.origin as CompiledEdgeOrigin.RelationWrapper).value.firstLocation }
                .distinct()
                .size shouldBe 2
        }
    }

    test("capturedUnavailableResourceBlocksCompilation") {
        val unavailableType = TypeDefinitionId.qualified("removed", "page")
        val unavailable =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(unavailableType.namedUse()),
                mapOf("legacy" to DataValue.StringValueWrapper("preserved")),
            )
        fixture(resources = mapOf(pageId to unavailable)).use { captured ->
            val result = with(captured.root) { compiler(captured.root).compile(pageId) } as ResourceGraphCompileResult.Blocked

            result.diagnostics.map { it.code }.toSet() shouldBe
                setOf("unresolved_type")
        }
    }
    test("an invalid ownership edge does not block an independent page") {
        val other = ResourceId("other")
        fixture(mapOf(pageId to pageRecord(listOf(missingId)), other to pageRecord(emptyList()))).use { captured ->
            val compiler = compiler(captured.root)
            with(captured.root) { compiler.compile(pageId) } as ResourceGraphCompileResult.Blocked
            val independent = with(captured.root) { compiler.compile(other) } as ResourceGraphCompileResult.Success
            independent.shard.facts.resources
                .map { it.key.source.toResourceId() } shouldBe listOf(other)
        }
    }

    test("a complete sibling cannot hide an unfinished owned resource") {
        val sibling = ResourceId("sibling")
        val unfinished = AuthoringRecord.of(childRecord("draft").configuration, mapOf("value" to DataValue.UNFILLED))
        val original = mapOf(pageId to pageRecord(listOf(childId)), childId to unfinished)
        val findings =
            listOf(original, original + (sibling to childRecord("complete"))).map { records ->
                fixture(records).use { captured ->
                    val result = with(captured.root) { compiler(captured.root).compile(pageId) } as ResourceGraphCompileResult.Blocked
                    result.diagnostics
                }
            }
        findings[0] shouldBe findings[1]
        findings[0].map { it.code } shouldBe listOf("unfinished_value")
        findings[0]
            .single()
            .primary!!
            .resource
            .toResourceId() shouldBe childId
    }
}

private fun compiler(view: com.typewritermc.realm.authoring.AuthoringView) =
    OwnershipClosureCompiler(
        setOf(OWNERSHIP),
        testAssessment(
            view,
            listOf(
                NativeBindingRequirement(
                    PAGE_USE,
                    skirout.editor.v1.type_catalog
                        .NativeBindingId(value = "page"),
                    "page_signature",
                ),
                NativeBindingRequirement(
                    CHILD_USE,
                    skirout.editor.v1.type_catalog
                        .NativeBindingId(value = "child"),
                    "child_signature",
                ),
                NativeBindingRequirement(
                    NESTED_USE,
                    skirout.editor.v1.type_catalog
                        .NativeBindingId(value = "nested"),
                    "nested_signature",
                ),
            ),
        ).resources,
    )

private fun fixture(
    resources: Map<ResourceId, AuthoringRecord>,
    snapshot: String = "snapshot_1",
): com.typewritermc.realm.authoring.AuthoringLease {
    val catalog = CompilerCatalogLease()
    val store =
        InMemoryAuthoringViewStore(
            catalog,
            AuthoringSeed(resources),
        )
    val captured = store.capture()
    store.close()
    return captured
}

private fun pageRecord(targets: List<ResourceId>) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(PAGE_USE),
        mapOf(
            "children" to
                DataValue.named(
                    CHILDREN_USE,
                    DataValue.listValue(
                        targets.mapIndexed { index, target ->
                            ListItem(
                                id = ItemId(value = "child_$index"),
                                value =
                                    DataValue.named(
                                        CHILD_LINK_USE,
                                        DataValue.createLink(
                                            endpoint = PAGE_ENDPOINT,
                                            target = LinkTarget(resource = target.toSkir(), opposite = null),
                                        ),
                                    ),
                            )
                        },
                    ),
                ),
        ),
    )

private fun childRecord(value: String) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(CHILD_USE),
        mapOf("value" to DataValue.StringValueWrapper(value)),
    )

/** A child that is a compilation unit itself. */
private fun nestedRecord() =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(NESTED_USE),
        mapOf("value" to DataValue.StringValueWrapper("nested")),
    )

private class CompilerCatalogLease private constructor(
    private val references: AtomicInteger,
) : AuthoringCatalogLease {
    constructor() : this(AtomicInteger(1))

    override val generation = CatalogGeneration(value = "compiler_catalog")
    override val checked: CheckedCatalog = DefaultCheckedCatalog(generation, DEFINITIONS)
    override val nativeBindings: NativeBindingRegistry = FactoryNativeBindingRegistry(checked, emptyList())
    override val providers = EmptyProviders
    override val checks = emptyList<com.typewritermc.discovery.OwnedCheckRecipe>()
    override val relations = listOf(OWNERSHIP_CONTRACT)
    override val endpointBindings = listOf(PAGE_BINDING)
    override val configuration: List<com.typewritermc.configuration.ConfigurationRecipe> = emptyList()
    override val operations = com.typewritermc.operations.OperationCatalog()
    override val placementFields = emptyMap<TypeDefinitionId, ValuePath>()

    override fun retain(): AuthoringCatalogLease {
        references.incrementAndGet()
        return CompilerCatalogLease(references)
    }

    override fun close() {
        check(references.decrementAndGet() >= 0)
    }
}

private val PAGE = TypeDefinitionId.qualified("compiler", "page")
private val CHILD = TypeDefinitionId.qualified("compiler", "child")
private val NESTED = TypeDefinitionId.qualified("compiler", "nested")
private val NESTED_USE = NESTED.namedUse()
private val CHILD_LINK = TypeDefinitionId.qualified("compiler", "child_link")
private val CHILDREN = TypeDefinitionId.qualified("compiler", "children")
private val PAGE_USE = PAGE.namedUse()
private val CHILD_USE = CHILD.namedUse()
private val CHILD_LINK_USE = CHILD_LINK.namedUse()
private val CHILDREN_USE = CHILDREN.namedUse()
private val OWNERSHIP = RelationId(value = "page_children")
private val PAGE_ENDPOINT = EndpointId(value = "page_children:first")
private val CHILD_ENDPOINT = EndpointId(value = "page_children:second")
private val OWNERSHIP_CONTRACT =
    RelationContract(
        OWNERSHIP,
        EndpointDefinition(
            PAGE_ENDPOINT,
            EndpointSlot.First,
            PAGE.namedTemplate(),
            EndpointCardinality.One,
            RelationDeletePolicy.CASCADE,
        ),
        EndpointDefinition(
            CHILD_ENDPOINT,
            EndpointSlot.Second,
            CHILD.namedTemplate(),
            EndpointCardinality.Many,
            RelationDeletePolicy.CLEAR,
        ),
    )
private val PAGE_BINDING =
    EndpointBindingTemplate(
        endpoint = PAGE_ENDPOINT,
        containingResource = PAGE.namedTemplate(),
        valueOwner = PAGE,
        relativePath = RelativeFieldPattern(listOf(FieldPatternSegment.Field("children"), FieldPatternSegment.Items)),
        target = CHILD.template(),
        containsCollection = true,
    )
private val DEFINITIONS =
    listOf(
        TypeDefinition.partial(
            id = PAGE,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(owner = FieldOwner(definition = PAGE, name = "children"), type = CHILDREN.template()),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = CHILD,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = CHILD, name = "value"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = false,
                ),
        ),
        TypeDefinition.partial(
            id = CompilationUnitDefinition.id,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
        ),
        TypeDefinition.partial(
            id = NESTED,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = NESTED, name = "value"),
                                type = ScalarKind.TEXT.template,
                                overrides = listOf(FieldOwner(definition = CHILD, name = "value")),
                            ),
                        ),
                    abstract_ = false,
                ),
            parents = listOf(CHILD.namedTemplate(), CompilationUnitDefinition.id.namedTemplate()),
        ),
        TypeDefinition.partial(
            id = CHILD_LINK,
            representation = RepresentationTemplate.createLink(endpoint = PAGE_ENDPOINT, target = CHILD.template()),
        ),
        TypeDefinition.partial(
            id = CHILDREN,
            representation = RepresentationTemplate.createSequence(item = CHILD_LINK.template(), kind = CollectionKind.LIST),
        ),
    )
