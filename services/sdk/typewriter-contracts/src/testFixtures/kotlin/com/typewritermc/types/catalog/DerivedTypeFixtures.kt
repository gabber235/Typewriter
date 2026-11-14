package com.typewritermc.types.catalog

import com.typewritermc.types.TEXT
import com.typewritermc.types.id
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

val DERIVING_BOARD = ResourceId(value = "board")

/** The type `V` [DERIVING_BOARD] derives. */
val DERIVED_V = TypeDefinitionId.derived(DERIVING_BOARD, "V")

/** A board whose `value` field holds its derived parameter `V`, next to a plain `name`. */
fun boardDefinition(): TypeDefinition {
    val id = id("board")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter(key = parameter, name = "V", bounds = emptyList(), derived = true)),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "name"), type = TEXT.toTemplate()),
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "value"), type = parameter.template),
                    ),
                form = RecordForm.CONCRETE,
            ),
    )
}

/** The record [DERIVING_BOARD] derives as `V`, with one field per pair. */
fun derivedRecord(vararg fields: Pair<String, TypeUse>): TypeDefinition =
    TypeDefinition.partial(
        id = DERIVED_V,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    fields.map { (name, type) ->
                        FieldDeclaration.partial(owner = FieldOwner(definition = DERIVED_V, name = name), type = type.toTemplate())
                    },
                form = RecordForm.CONCRETE,
            ),
    )

/** Content in which [DERIVING_BOARD] derives [target] as `V` and declares nothing written. */
fun derives(target: DerivedTarget): ContentTypes =
    object : ContentTypes {
        override fun written(owner: ResourceId): List<TypeDefinition> = emptyList()

        override fun heldType(
            owner: ResourceId,
            field: String,
        ): TypeUse? = null

        override fun derived(
            owner: ResourceId,
            key: String,
        ): DerivedTarget = if (owner == DERIVING_BOARD && key == "V") target else DerivedTarget.Missing(DerivedFailure.NoBlock)
    }

/** The field names of [use] in this catalog. */
fun CheckedCatalog.fieldsOf(use: TypeUse): List<String> =
    (resolve(use) as Resolution.Ready)
        .value.schema.fields
        .map { it.key }
