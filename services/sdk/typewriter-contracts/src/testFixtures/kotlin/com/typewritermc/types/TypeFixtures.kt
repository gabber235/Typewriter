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
            abstract_ = parent == null,
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
    TypeDefinition.partial(id = id(name), representation = RepresentationTemplate.createRecord(fields = fields.toList(), abstract_ = false))

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
                abstract_ = true,
            ),
    )
}

fun rewardDefinition(resource: TypeDefinitionId): TypeDefinition {
    val id = id("reward")
    return TypeDefinition.partial(
        id = id,
        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
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
                abstract_ = false,
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
                abstract_ = false,
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
                abstract_ = false,
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
                abstract_ = false,
            ),
    )
}
