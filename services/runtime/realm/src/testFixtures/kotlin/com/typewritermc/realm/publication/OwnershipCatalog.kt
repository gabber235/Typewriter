package com.typewritermc.realm.publication

import com.typewritermc.authoring.CompilationUnitDefinition
import com.typewritermc.authoring.of
import com.typewritermc.engine.ResourceGraphCompileResult
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
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
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
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** Compiles [root] from [resources] saved on the compiler catalog, with readiness from production acceptance. */
internal suspend fun compileOwnershipClosure(
    resources: Map<ResourceId, AuthoringRecord>,
    root: ResourceId,
): ResourceGraphCompileResult =
    InMemoryAuthoringViewStore(COMPILER_CATALOG.lease(), AuthoringSeed(resources)).use { store ->
        RealmCheckRuntime(store).use { checks ->
            val acceptance = AuthoringAcceptance(store, checks)
            acceptance.capture().use { captured ->
                val readiness = acceptance.evaluate(captured).resources
                with(captured.root) { OwnershipClosureCompiler(setOf(OWNERSHIP_RELATION), readiness).compile(root) }
            }
        }
    }

/** The authored location of the page's child link item number [index]. */
internal fun ownershipChildPath(index: Int) =
    ValuePath(segments = listOf(PathSegment.createField(name = "children"), PathSegment.createItem(id = ItemId(value = "child_$index"))))

/** A complete compiler page that owns [targets] through its children list, one item per target in order. */
internal fun ownershipPageRecord(targets: List<ResourceId>) =
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

/** A complete compiler child whose text value is [value]. */
internal fun ownershipChildRecord(value: String) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(CHILD_USE),
        mapOf("value" to DataValue.StringValueWrapper(value)),
    )

/** A child that is a compilation unit itself. */
internal fun ownershipNestedRecord() =
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

/** The ownership relation from a compiler page to the children it lists. */
internal val OWNERSHIP_RELATION = RelationId(value = "page_children")
private val PAGE_ENDPOINT = EndpointId(value = "page_children:first")
private val CHILD_ENDPOINT = EndpointId(value = "page_children:second")
private val OWNERSHIP_CONTRACT =
    RelationContract.of(
        OWNERSHIP_RELATION,
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
