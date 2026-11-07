@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.testing

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.ReachabilityQuery
import com.typewritermc.authoring.ResourceDrafts
import com.typewritermc.authoring.boundPath
import com.typewritermc.authoring.exactEditablePath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.reverse
import com.typewritermc.authoring.root
import com.typewritermc.engine.pages.Definition
import com.typewritermc.engine.pages.StaticPageDefinition
import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.Var
import com.typewritermc.formula.VarDefinition
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.RealmGraphReads
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.RelationReads
import com.typewritermc.realm.authoring.tracked
import com.typewritermc.realm.catalog.code
import com.typewritermc.realm.catalog.over
import com.typewritermc.realm.edit.WorkingViewEditContext
import com.typewritermc.realm.operation.operationObservation
import com.typewritermc.testing.routes.FixtureStaticEntryDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.content
import com.typewritermc.types.catalog.contentField
import com.typewritermc.types.catalog.unavailableCode
import com.typewritermc.types.endpointId
import com.typewritermc.types.functionUse
import com.typewritermc.types.listValue
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.ScalarRepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
import com.typewritermc.types.ResourceId as AuthorResourceId

/*
 * Content types as a client sends them: declarations on the resource that owns them, and the uses that name them. A
 * declaration's id names its owner, so content types are built once the owner's id is known.
 */

/** The type a position names and the declarations it needs, all on one owner. */
class DeclaredTypes(
    val use: TypeUse,
    val types: List<TypeDefinition>,
)

/** Content types built for the resource that declares them. */
fun interface ContentTypes {
    fun on(owner: ResourceId): DeclaredTypes
}

/** The content types [build] declares on their owner, naming the use it returns. */
fun declares(build: ContentTypeScope.() -> TypeUse): ContentTypes =
    ContentTypes { owner ->
        val scope = ContentTypeScope(owner)
        val use = scope.build()
        DeclaredTypes(use, scope.declarations.toList())
    }

/** A type with no declarations of its own, such as a code type or a field key of another resource. */
fun plainType(use: TypeUse): ContentTypes = ContentTypes { DeclaredTypes(use, emptyList()) }

/** Declares content types on one owner. Keys are generated in declaration order unless given. */
class ContentTypeScope internal constructor(
    val owner: ResourceId,
) {
    internal val declarations = mutableListOf<TypeDefinition>()
    private var keys = 0

    /** The id of the declaration [key] on the owner. */
    fun id(key: String): TypeDefinitionId = TypeDefinitionId.content(owner, key)

    /** A record declared as [key], with the fields and form [build] sets. */
    fun record(
        key: String = nextKey(),
        build: TypeDefinitionBuilder.() -> Unit = {},
    ): TypeUse = declare(TypeDefinitionBuilder(id(key)).apply(build).build())

    /** A closed union declared as [key] with the cases [build] lists, in order. */
    fun union(
        key: String = nextKey(),
        build: UnionBuilder.() -> Unit,
    ): TypeUse {
        val union = id(key)
        val cases = UnionBuilder(union).apply(build).cases
        cases.forEach(::declare)
        return declare(
            TypeDefinitionBuilder(union).apply { form = RecordForm.createClosed(cases = cases.map { it.id.namedTemplate() }) }.build(),
        )
    }

    /** [definition] exactly as given, for declarations no builder would make. */
    fun declare(definition: TypeDefinition): TypeUse {
        declarations += definition
        return definition.id.use()
    }

    private fun nextKey(): String = "k${++keys}"
}

/** The cases of one closed union, each naming the union as its parent. */
class UnionBuilder internal constructor(
    private val union: TypeDefinitionId,
) {
    internal val cases = mutableListOf<TypeDefinition>()

    /** The case [name]; with no fields it is a unit case, as an enum's are. */
    fun case(
        name: String,
        build: TypeDefinitionBuilder.() -> Unit = {},
    ) {
        cases += TypeDefinitionBuilder(union.member(name)).apply { parent(union) }.apply(build).build(unitWhenEmpty = true)
    }
}

/** The fields, form, parents and parameters of one declaration. */
class TypeDefinitionBuilder internal constructor(
    val id: TypeDefinitionId,
) {
    private val fields = mutableListOf<FieldDeclaration>()
    private val parents = mutableListOf<TypeDefinitionId>()
    private val parameters = mutableListOf<String>()

    /** The record form; concrete unless set. */
    var form: RecordForm = RecordForm.CONCRETE

    /** A field [name] holding [type], declared by [owner], which is this declaration unless given. */
    fun field(
        name: String,
        type: TypeUse,
        owner: TypeDefinitionId = id,
    ) {
        fields +=
            FieldDeclaration(
                owner = FieldOwner(definition = owner, name = name),
                type = type.toTemplate(),
                overrides = emptyList(),
                hasConstructorDefault = false,
            )
    }

    /** Names [parent] as a parent of this declaration. */
    fun parent(parent: TypeDefinitionId) {
        parents += parent
    }

    /** A type parameter [name], which content may not declare. */
    fun parameter(name: String) {
        parameters += name
    }

    internal fun build(unitWhenEmpty: Boolean = false): TypeDefinition =
        TypeDefinition(
            id = id,
            parameters =
                parameters.mapIndexed {
                    index,
                    name,
                    ->
                    TypeParameter(key = ParameterKey(owner = id, index = index), name = name, bounds = emptyList())
                },
            representation =
                if (unitWhenEmpty && fields.isEmpty() && form == RecordForm.CONCRETE) {
                    RepresentationTemplate.ScalarWrapper(ScalarRepresentationTemplate(kind = ScalarKind.UNIT))
                } else {
                    RepresentationTemplate.createRecord(fields = fields.toList(), form = form)
                },
            parents = parents.map { it.namedTemplate() },
        )
}

/** A record declaration [id] with no fields, of [form], naming [parent] when given: for declarations no builder would make. */
fun recordDefinition(
    id: TypeDefinitionId,
    form: RecordForm = RecordForm.CONCRETE,
    parent: TypeDefinitionId? = null,
): TypeDefinition =
    TypeDefinition(
        id = id,
        parameters = emptyList(),
        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = form),
        parents = listOfNotNull(parent?.namedTemplate()),
    )

/** The use that means whatever the field [field] of [resource] holds, such as an alias's value. */
fun fieldKey(
    resource: ResourceId,
    field: String = "value",
): TypeUse = TypeDefinitionId.contentField(resource, field).use()

/** A list of [item]. */
fun listType(item: TypeUse): TypeUse = StandardTypes.list.namedUse(listOf(item)).use

/** `Ref<T>` as content writes it: a content reference to a resource of [target]. */
fun refTo(target: TypeUse): TypeUse =
    ContentReferences.Source.Definition.id
        .namedUse(listOf(target))
        .use

/** `Ref<FixtureStaticEntry>`, the reference type the demos hold. */
val entryRef: TypeUse = refTo(FixtureStaticEntryDefinition.id.use())

/** A content reference to [target] stored at a position of the reference type [type]. */
fun contentLink(
    target: ResourceId,
    type: TypeUse = entryRef,
): DataValue = linkValue(checkNotNull(type.named), ContentReferences.id.endpointId(EndpointSlot.FIRST), target)

/** A list value of a list of [item] holding [items], each under an item id named after its position. */
fun listValue(
    item: TypeUse,
    vararg items: DataValue,
): DataValue =
    DataValue.named(
        checkNotNull(listType(item).named),
        DataValue.listValue(items.mapIndexed { index, value -> ListItem(id = ItemId(value = "item-$index"), value = value) }),
    )

/** Points the field [field] of the record a Definition [resource] of [type] holds plainly at [target]. */
fun setReference(
    resource: ResourceId,
    field: String,
    target: ResourceId,
    type: TypeUse = entryRef,
): EditIntent =
    EditIntent.createSetValue(
        at =
            plainValueLocation(resource).let {
                it.copy(path = it.path.field(field))
            },
        value = contentLink(target, type),
    )

/**
 * The resources that hold a content reference to [target], as a check reads them through the graph: one step back
 * along the content references relation.
 */
fun RealmFixture.usagesOf(target: ResourceId): List<ResourceId> = views.pin().use { it.reads.read(UsagesOf(target)) }

/** How often the graph computed the usages of [target] so far. */
internal fun RealmFixture.usageRuns(target: ResourceId): Long = graphRuns.runsOf(UsagesOf(target))

/** The resources [target] is graph linked with, read through the graph as a check over its links reads them. */
internal fun RealmFixture.graphLinksOf(target: ResourceId): List<ResourceId> = views.pin().use { it.reads.read(GraphLinksOf(target)) }

/** How often the graph computed the graph links of [target] so far. */
internal fun RealmFixture.graphLinkRuns(target: ResourceId): Long = graphRuns.runsOf(GraphLinksOf(target))

/** A check over graph links: the other end of each graph link [target] holds or is the target of. */
internal data class GraphLinksOf(
    val target: ResourceId,
) : RealmQuery<List<ResourceId>> {
    context(reads: RealmReads)
    override fun compute(): List<ResourceId> =
        RelationReads(tracked()).linksOf(target).map { if (it.source == target) it.target.resource else it.source }
}

/** A check over usages: the resources whose content names [target], read through the graph. */
internal data class UsagesOf(
    val target: ResourceId,
) : RealmQuery<List<ResourceId>> {
    context(reads: RealmReads)
    override fun compute(): List<ResourceId> =
        with(tracked()) {
            RealmGraphReads
                .reachable(ReachabilityQuery(setOf(target.toResourceId()), ContentReferences.id.reverse(), ResourceDrafts, maxDepth = 1))
                .resources
                .map { it.id.toSkir() }
                .filter { it != target }
        }
}

/** A Definition's value written plainly as [value], stored as the value of a Definition of [type]. */
fun plainVar(
    type: TypeUse,
    value: DataValue,
): DataValue =
    DataValue.named(
        VarDefinition.id.member("Value").namedUse(listOf(type, functionUse(result = type))),
        DataValue.record("value" to value),
    )

/** A value of the record type [type] holding [fields]. */
fun recordValue(
    type: TypeUse,
    vararg fields: Pair<String, DataValue>,
): DataValue = DataValue.named(checkNotNull(type.named), DataValue.record(*fields))

/** The value of the unit case [case] of the union [union]. */
fun caseValue(
    union: TypeUse,
    case: String,
): DataValue = DataValue.named(checkNotNull(union.named).definition.member(case).namedUse(), DataValue.UNIT)

/** The value of the case [case] of the union [union], holding [fields]. */
fun caseValue(
    union: TypeUse,
    case: String,
    vararg fields: Pair<String, DataValue>,
): DataValue = DataValue.named(checkNotNull(union.named).definition.member(case).namedUse(), DataValue.record(*fields))

/** The type of a Definition whose value is itself a type. */
val typeUse: TypeUse = ScalarKind.TYPE.use

/** A create that commits, and the id of what it created. */
class Creation(
    val id: ResourceId,
    val reply: CommitPreparedEditResponse,
) {
    /** Asserts the create committed and returns the created id. */
    fun created(): ResourceId {
        reply.shouldBeCommitted()
        return id
    }
}

/**
 * Creates a Definition on the realm's static page whose type argument is what [declared] builds on it, holding what
 * [value] gives for those types, and commits it.
 */
suspend fun RealmFixture.commitDefinition(
    name: String,
    declared: ContentTypes,
    value: (DeclaredTypes) -> DataValue = { DataValue.UNFILLED },
): Creation {
    val (id, reply) =
        commitElement { id ->
            val types = declared.on(id)
            definitionRecord(name, types.use, value(types), types.types)
        }
    return Creation(id, reply)
}

/**
 * What an operation reads of the value of the Definition named [name] it has just created with the types [declared]
 * builds and the value [value], inside the same edit before anything commits, beside the types it declared.
 */
suspend fun RealmFixture.readJustCreated(
    name: String,
    declared: ContentTypes,
    value: (DeclaredTypes) -> DataValue,
): Pair<DeclaredTypes, Availability<Any?>> {
    lateinit var types: DeclaredTypes
    val (id, writes) =
        elementWrites { id ->
            types = declared.on(id)
            definitionRecord(name, types.use, value(types), types.types)
        }
    return views.capture().use { lease ->
        WorkingViewEditContext(lease.root, "read-just-created").run {
            writes()
            types to read(boundPath<Any?>(plainValueLocation(id), types.use))
        }
    }
}

/**
 * Commits one operation edit that creates the Definition named [name] with the types [declared] builds and no value,
 * then writes the Kotlin value [value] builds from those types as its value, the way an operation sets a field.
 */
suspend fun RealmFixture.commitCreateThenSet(
    name: String,
    declared: ContentTypes,
    value: (DeclaredTypes) -> Var<*, *>,
): Creation {
    lateinit var types: DeclaredTypes
    val (id, writes) =
        elementWrites { id ->
            types = declared.on(id)
            definitionRecord(name, types.use, DataValue.UNFILLED, types.types)
        }
    val reply =
        commit {
            writes()
            val definition = binding(boundPath<Any?>(ValueLocation.of(id), TypeUse.NamedWrapper(definitionOf(types.use))))
            val path =
                (definition as Availability.Available).value.exactEditablePath<Any?>(
                    ValuePath.root.field("value"),
                    definitionValueUse(types.use),
                )
            set(path, value(types))
        }
    return Creation(id, reply)
}

/** Creates and commits a Definition named [name] whose type is what [type] holds, valued as a record of [fields]; returns its id. */
suspend fun RealmFixture.commitRecordUser(
    name: String,
    type: ResourceId,
    vararg fields: Pair<String, DataValue>,
): ResourceId = commitDefinition(name, plainType(fieldKey(type))) { plainVar(it.use, recordValue(it.use, *fields)) }.created()

/** Creates and commits a Definition of Type named [name] holding the type [held] builds on it: an alias, or a named custom type. */
suspend fun RealmFixture.commitTypeDefinition(
    name: String,
    held: ContentTypes,
): Creation {
    val (id, reply) =
        commitElement { id ->
            val types = held.on(id)
            definitionRecord(name, typeUse, plainVar(typeUse, DataValue.TypeUseWrapper(types.use)), types.types)
        }
    return Creation(id, reply)
}

private fun RealmFixture.definitionRecord(
    name: String,
    type: TypeUse,
    value: DataValue,
    types: List<TypeDefinition>,
): AuthoringRecord {
    val page = resources.typesOf(StaticPageDefinition.id).single()
    val template =
        encoder.record(
            definitionOf(intUse).use,
            Definition(Ref(AuthorResourceId(page.value)), GraphPlacement(), name, Var.Value(0)),
        )
    return template.copy(
        configuration = TypeSelection.CompleteWrapper(definitionOf(type)),
        fields = template.fields.map { if (it.name == "value") it.copy(value = value) else it },
        types = types,
    )
}

/** Replaces the types [resource] declares with [types]. */
fun setTypes(
    resource: ResourceId,
    types: List<TypeDefinition>,
): EditIntent = EditIntent.createSetTypes(resource = resource, types = types)

/** Replaces the types [resource] declares with what [declared] builds on it. */
fun setTypes(
    resource: ResourceId,
    declared: ContentTypes,
): EditIntent = setTypes(resource, declared.on(resource).types)

/** Writes [value] as the value of the Definition [resource]. */
fun setDefinitionValue(
    resource: ResourceId,
    value: DataValue,
): EditIntent = EditIntent.createSetValue(at = ValueLocation.of(resource, ValuePath.root.field("value")), value = value)

/** The types [resource] declares now. */
fun RealmFixture.declaredTypes(resource: ResourceId): List<TypeDefinition> = record(resource).types

/** The schema of [resource]'s configuration, resolved by the saved view's catalog. */
fun RealmFixture.schemaOf(resource: ResourceId): Resolution<CheckedType> =
    viewCatalog.resolve(TypeUse.NamedWrapper((record(resource).configuration as TypeSelection.CompleteWrapper).value))

/** Asserts whether this resolution is ready. */
infix fun Resolution<*>.shouldBeReady(ready: Boolean) {
    (this is Resolution.Ready) shouldBe ready
}

/** What the saved view's catalog says about [id]. */
fun RealmFixture.statusOf(id: TypeDefinitionId): DeclarationStatus = viewCatalog.definition(id)

/** The code that says why the saved view's catalog answers [use] with the error type, or null when it is ready. */
fun RealmFixture.unavailableCodeOf(use: TypeUse): String? = viewCatalog.unavailableCode(checkNotNull(use.named).definition)

/** The resolved schema of [use] in the saved view's catalog; fails when it does not resolve. */
fun RealmFixture.resolvedSchema(use: TypeUse): CheckedType =
    viewCatalog.resolve(use).shouldBeInstanceOf<Resolution.Ready<CheckedType>>().value

/** The type argument of the Definition [resource]. */
fun RealmFixture.typeArgumentOf(resource: ResourceId): TypeUse =
    (record(resource).configuration as TypeSelection.CompleteWrapper).value.arguments.single()

/** The saved view's catalog: the code catalog plus every saved declaration. */
val RealmFixture.viewCatalog: CheckedCatalog get() = views.read { view -> view.catalog.checked }

/** The catalog a view of the saved state with [upserts] replaced would have, without admitting that state. */
fun RealmFixture.catalogOver(upserts: Map<ResourceId, AuthoringRecord>): CheckedCatalog =
    views.read { view ->
        view.catalog.over(view.resources + upserts).checked
    }

/** The code catalog alone, without any declaration a resource holds. */
val RealmFixture.codeCatalog: CheckedCatalog get() = views.read { view -> view.catalog.code.checked }

/**
 * What an operation over a draft of the saved state with [upserts] replaced reads through [read]; throws the refusal
 * when the draft is refused.
 */
fun <T> RealmFixture.overDraft(
    upserts: Map<ResourceId, AuthoringRecord>,
    read: (CheckedCatalog) -> T,
): T = views.capture().use { lease -> read(lease.operationObservation(lease.root.observationId, upserts, emptySet()).catalog.checked) }
