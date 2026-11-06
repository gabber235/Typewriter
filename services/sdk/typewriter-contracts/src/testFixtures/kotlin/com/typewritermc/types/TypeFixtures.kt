package com.typewritermc.types

import com.typewritermc.authoring.of
import com.typewritermc.configuration.field
import com.typewritermc.configuration.of
import com.typewritermc.presentation.of
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate

/** A link type [definition] through its own endpoint, whose target is its first parameter. */
fun linkDefinition(definition: TypeDefinitionId) =
    TypeDefinition.partial(
        id = definition,
        parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = definition, index = 0), name = "T")),
        representation =
            RepresentationTemplate.createLink(
                endpoint = EndpointId(value = definition.toString()),
                target = ParameterKey(owner = definition, index = 0).template,
            ),
    )

/** A use of [link] with [target] as its argument. */
fun referenceTo(
    link: TypeDefinitionId,
    target: TypeDefinitionId,
) = link.template(listOf(target.template()))

/** The list of [target] links through [elementLink], where [list] is the list type. */
fun elementsOf(
    list: TypeDefinitionId,
    elementLink: TypeDefinitionId,
    target: TypeDefinitionId,
) = list.template(listOf(referenceTo(elementLink, target)))

/** A record type [definition] with one field [name] of [type], inheriting the same field from [parent] when given. */
fun fieldRecord(
    definition: TypeDefinitionId,
    name: String,
    type: TypeTemplate,
    parent: TypeDefinitionId? = null,
) = TypeDefinition.partial(
    id = definition,
    representation =
        RepresentationTemplate.createRecord(
            fields =
                listOf(
                    FieldDeclaration.partial(
                        owner = FieldOwner(definition = definition, name = name),
                        type = type,
                        overrides =
                            parent
                                ?.let {
                                    listOf(FieldOwner(definition = it, name = name))
                                }.orEmpty(),
                    ),
                ),
            form = if (parent == null) RecordForm.OPEN else RecordForm.CONCRETE,
        ),
    parents = parent?.let { listOf(it.namedTemplate()) }.orEmpty(),
)

/** The list value of [children] under the list type [listUse]. */
fun sequenceValue(
    listUse: NamedTypeUse,
    children: List<DataValue>,
): DataValue =
    DataValue.named(
        listUse,
        DataValue.listValue(children.mapIndexed { index, value -> ListItem(id = ItemId(value = "item$index"), value = value) }),
    )

/** A tree node of [children] under the tree type [treeUse], whose children list is typed by [listUse]. */
fun nodeValue(
    treeUse: NamedTypeUse,
    listUse: NamedTypeUse,
    children: List<DataValue>,
): DataValue = DataValue.named(treeUse, DataValue.record(mapOf("children" to sequenceValue(listUse, children))))

val TEXT = ScalarKind.TEXT.use
val TEXT_TEMPLATE = ScalarKind.TEXT.template

fun catalog(vararg definitions: TypeDefinition) = DefaultCheckedCatalog(CatalogGeneration(value = "test"), definitions.toList())

fun id(name: String) = TypeDefinitionId.qualified("test", name)

fun field(
    owner: String,
    name: String,
    type: TypeTemplate,
) = FieldDeclaration.partial(owner = FieldOwner(definition = id(owner), name = name), type = type)

fun recordDefinition(
    name: String,
    vararg fields: FieldDeclaration,
): TypeDefinition =
    TypeDefinition.partial(
        id = id(name),
        representation = RepresentationTemplate.createRecord(fields = fields.toList(), form = RecordForm.CONCRETE),
    )

fun resourceDefinition(): TypeDefinition {
    val id = id("resource")
    return TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "name"), type = TEXT_TEMPLATE),
                    ),
                form = RecordForm.OPEN,
            ),
    )
}

fun rewardDefinition(resource: TypeDefinitionId): TypeDefinition {
    val id = id("reward")
    return TypeDefinition.partial(
        id = id,
        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
        parents = listOf(resource.namedTemplate()),
    )
}

fun weightedDefinition(): TypeDefinition {
    val id = id("weighted")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "value"), type = parameter.template),
                    ),
                form = RecordForm.CONCRETE,
            ),
    )
}

fun variableDefinition(resource: TypeDefinitionId): TypeDefinition {
    val id = id("variable")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition(
        id = id,
        parameters = listOf(TypeParameter(key = parameter, name = "T", bounds = listOf(resource.template()))),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "value"), type = parameter.template),
                    ),
                form = RecordForm.CONCRETE,
            ),
        parents = listOf(resource.namedTemplate()),
    )
}

fun listDefinition(): TypeDefinition {
    val id = id("list")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
        representation = RepresentationTemplate.createSequence(item = parameter.template, kind = CollectionKind.LIST),
    )
}

fun treeDefinition(list: TypeDefinitionId): TypeDefinition {
    val id = id("tree")
    val parameter = ParameterKey(owner = id, index = 0)
    val tree = id.template(listOf(parameter.template))
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = id, name = "children"),
                            type = list.template(listOf(tree)),
                        ),
                    ),
                form = RecordForm.CONCRETE,
            ),
    )
}

fun optionalDefinition(): TypeDefinition {
    val id = id("optional")
    return TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "note"), type = TEXT_TEMPLATE.nullable()),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = id, name = "count"),
                            type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                        ),
                    ),
                form = RecordForm.CONCRETE,
            ),
    )
}

/** A record [definition] without fields that accepts only [cases], in that order. */
fun closedRecord(
    definition: TypeDefinitionId,
    cases: List<TypeDefinitionId>,
): TypeDefinition =
    TypeDefinition.partial(
        id = definition,
        representation =
            RepresentationTemplate.createRecord(
                fields = emptyList(),
                form = RecordForm.createClosed(cases = cases.map { it.namedTemplate() }),
            ),
    )

/** A unit case [name] of [owner], naming [parent] as its parent when given. */
fun unitCase(
    owner: TypeDefinitionId,
    name: String,
    parent: TypeDefinitionId? = owner,
): TypeDefinition =
    TypeDefinition.partial(
        id = owner.member(name),
        representation = RepresentationTemplate.createScalar(kind = ScalarKind.UNIT),
        parents = listOfNotNull(parent?.namedTemplate()),
    )

/** The enum [owner] listing [cases] in order, followed by its case definitions. */
fun enumDefinitions(
    owner: TypeDefinitionId,
    vararg cases: String,
): List<TypeDefinition> = listOf(closedRecord(owner, cases.map(owner::member))) + cases.map { unitCase(owner, it) }

/** A record [definition] without fields of [form], under [parents]. */
fun bareRecord(
    definition: TypeDefinitionId,
    form: RecordForm,
    vararg parents: TypeDefinitionId,
): TypeDefinition =
    TypeDefinition.partial(
        id = definition,
        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = form),
        parents = parents.map { it.namedTemplate() },
    )

/** The value of the unit case [name] of [owner]. */
fun caseValue(
    owner: TypeDefinitionId,
    name: String,
): DataValue = DataValue.named(owner.member(name).namedUse(), DataValue.UNIT)

/** The codes of the declaration problems that make [id] unavailable, or none when it is ready. */
fun com.typewritermc.types.catalog.CheckedCatalog.unavailableCodes(id: TypeDefinitionId): List<String> =
    (definition(id) as? skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper)?.value.orEmpty().map { it.code }
