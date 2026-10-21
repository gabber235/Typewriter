package com.typewritermc.types

import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

/**
 * Builtin collection definitions every catalog contains.
 *
 * Each builtin is an object owning its id, the same shape as a generated `XDefinition`, so generated code
 * references `StandardTypes.List.id` like any other definition owner.
 */
object StandardTypes {
    object List {
        val id: TypeDefinitionId = TypeDefinitionId.qualified("typewriter", "List")
    }

    object Set {
        val id: TypeDefinitionId = TypeDefinitionId.qualified("typewriter", "Set")
    }

    object Map {
        val id: TypeDefinitionId = TypeDefinitionId.qualified("typewriter", "Map")
    }

    val list: TypeDefinitionId get() = List.id
    val set: TypeDefinitionId get() = Set.id
    val map: TypeDefinitionId get() = Map.id

    private val listItem = parameter(list, 0, "T")
    private val setItem = parameter(set, 0, "T")
    private val mapKey = parameter(map, 0, "K")
    private val mapValue = parameter(map, 1, "V")

    val definitions: kotlin.collections.List<TypeDefinition> =
        listOf(
            TypeDefinition(
                id = list,
                parameters = listOf(listItem),
                representation = RepresentationTemplate.createSequence(item = listItem.key.template, kind = CollectionKind.LIST),
                parents = emptyList(),
            ),
            TypeDefinition(
                id = set,
                parameters = listOf(setItem),
                representation = RepresentationTemplate.createSequence(item = setItem.key.template, kind = CollectionKind.SET),
                parents = emptyList(),
            ),
            TypeDefinition(
                id = map,
                parameters = listOf(mapKey, mapValue),
                representation = RepresentationTemplate.createMapping(key = mapKey.key.template, value = mapValue.key.template),
                parents = emptyList(),
            ),
        )

    private fun parameter(
        owner: TypeDefinitionId,
        index: Int,
        name: String,
    ) = TypeParameter(key = ParameterKey(owner = owner, index = index), name = name, bounds = emptyList())
}
