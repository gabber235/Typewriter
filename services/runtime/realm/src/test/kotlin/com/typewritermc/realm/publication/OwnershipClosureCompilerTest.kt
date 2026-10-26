package com.typewritermc.realm.publication

import com.typewritermc.authoring.CompilationUnitDefinition
import com.typewritermc.authoring.of
import com.typewritermc.engine.ResourceGraphCompileResult
import com.typewritermc.engine.relation
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.recordBinding
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.compiled_content.CompiledEdgeOrigin
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

private val pageId = ResourceId(value = "page")
private val childId = ResourceId(value = "child")
private val missingId = ResourceId(value = "missing")

val OwnershipClosureCompilerTest by testSuite {
    test("one sided ownership links compile the complete owned shard") {
        val result = compile(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("first")), pageId)

        result as ResourceGraphCompileResult.Success
        result.shard.facts.resources
            .map { it.key.source }
            .toSet() shouldBe setOf(pageId, childId)
        result.shard.facts.edges.single().let { edge ->
            edge.source.source shouldBe pageId
            edge.target.source shouldBe childId
            edge.relation shouldBe OWNERSHIP
        }
    }

    test("authored content changes produce a new shard identity") {
        val first = compile(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("first")), pageId)
        val second = compile(mapOf(pageId to pageRecord(listOf(childId)), childId to childRecord("second")), pageId)

        first as ResourceGraphCompileResult.Success
        second as ResourceGraphCompileResult.Success
        (second.inputFingerprint == first.inputFingerprint) shouldBe false
        (second.shard.digest == first.shard.digest) shouldBe false
    }

    test("a nested compilation unit is its own shard, not part of its owner's") {
        val nested = ResourceId(value = "nested")
        val records = mapOf(pageId to pageRecord(listOf(childId, nested)), childId to childRecord("first"), nested to nestedRecord())
        val page = compile(records, pageId) as ResourceGraphCompileResult.Success
        val unit = compile(records, nested) as ResourceGraphCompileResult.Success

        page.shard.facts.resources
            .map { it.key.source }
            .toSet() shouldBe setOf(pageId, childId)
        page.shard.facts.edges
            .map { it.target.source }
            .toSet() shouldBe setOf(childId, nested)
        unit.shard.facts.resources
            .map { it.key.source } shouldBe listOf(nested)
    }

    test("missing owned resources block publication") {
        val result = compile(mapOf(pageId to pageRecord(listOf(missingId))), pageId)

        result as ResourceGraphCompileResult.Blocked
        result.diagnostics.single().code shouldBe "missing_owned_resource"
    }

    test("parallel occurrences retain distinct endpoint locations") {
        val result =
            compile(mapOf(pageId to pageRecord(listOf(childId, childId)), childId to childRecord("child")), pageId)
                as ResourceGraphCompileResult.Success

        result.shard.facts.edges
            .map { (it.origin as CompiledEdgeOrigin.RelationWrapper).value.firstLocation }
            .toSet() shouldBe setOf(childPath(0), childPath(1))
    }

    test("a resource whose type the catalog no longer declares blocks its shard with unresolved_type") {
        val unavailable =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(TypeDefinitionId.qualified("removed", "page").namedUse()),
                mapOf("legacy" to DataValue.StringValueWrapper("preserved")),
            )
        val result = compile(mapOf(pageId to unavailable), pageId) as ResourceGraphCompileResult.Blocked

        result.diagnostics.map { it.code to it.primary } shouldBe listOf("unresolved_type" to ValueLocation.of(pageId))
    }

    test("an invalid ownership edge does not block an independent page") {
        val other = ResourceId(value = "other")
        val records = mapOf(pageId to pageRecord(listOf(missingId)), other to pageRecord(emptyList()))

        compile(records, pageId).shouldBeInstanceOf<ResourceGraphCompileResult.Blocked>()
        val independent = compile(records, other) as ResourceGraphCompileResult.Success
        independent.shard.facts.resources
            .map { it.key.source } shouldBe listOf(other)
    }

    test("a complete sibling cannot hide an unfinished owned resource") {
        val sibling = ResourceId(value = "sibling")
        val unfinished = AuthoringRecord.of(childRecord("draft").configuration, mapOf("value" to DataValue.UNFILLED))
        val original = mapOf(pageId to pageRecord(listOf(childId)), childId to unfinished)
        val findings =
            listOf(original, original + (sibling to childRecord("complete"))).map { records ->
                (compile(records, pageId) as ResourceGraphCompileResult.Blocked).diagnostics
            }

        findings[0] shouldBe findings[1]
        findings[0].map { it.code to it.primary?.resource } shouldBe listOf("unfinished_value" to childId)
    }
}

/** Compiles [root] from [resources] saved on the compiler catalog, with readiness from production acceptance. */
private suspend fun compile(
    resources: Map<ResourceId, AuthoringRecord>,
    root: ResourceId,
): ResourceGraphCompileResult =
    InMemoryAuthoringViewStore(COMPILER_CATALOG.lease(), AuthoringSeed(resources)).use { store ->
        RealmCheckRuntime(store).use { checks ->
            val acceptance = AuthoringAcceptance(store, checks)
            acceptance.capture().use { captured ->
                val readiness = acceptance.evaluate(captured).resources
                with(captured.root) { OwnershipClosureCompiler(setOf(OWNERSHIP), readiness).compile(root) }
            }
        }
    }

/** The authored location of the page's child link item number [index]. */
private fun childPath(index: Int) =
    ValuePath(segments = listOf(PathSegment.createField(name = "children"), PathSegment.createItem(id = ItemId(value = "child_$index"))))

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
                                            target = LinkTarget(resource = target, opposite = null),
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
    RelationContract.of(
        OWNERSHIP,
        EndpointDefinition(
            id = PAGE_ENDPOINT,
            slot = EndpointSlot.FIRST,
            resource = PAGE.namedTemplate(),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CASCADE,
        ),
        EndpointDefinition(
            id = CHILD_ENDPOINT,
            slot = EndpointSlot.SECOND,
            resource = CHILD.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
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
private val COMPILER_CATALOG =
    DefinitionCatalog(
        DEFINITIONS,
        relations = listOf(OWNERSHIP_CONTRACT),
        nativeBindingFactories = listOf(PAGE, CHILD, NESTED).map { recordBinding(it) },
    )
