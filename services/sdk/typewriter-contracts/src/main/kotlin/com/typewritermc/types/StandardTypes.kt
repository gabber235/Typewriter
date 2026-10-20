package com.typewritermc.types

/**
 * Builtin collection definitions every catalog contains.
 *
 * Each builtin is an object owning its id, the same shape as a generated `XDefinition`, so generated code
 * references `StandardTypes.List.id` like any other definition owner.
 */
object StandardTypes {
    object List {
        val id: TypeDefinitionId = TypeDefinitionId(TypeId.Qualified("typewriter", "List"), 1)
    }

    object Set {
        val id: TypeDefinitionId = TypeDefinitionId(TypeId.Qualified("typewriter", "Set"), 1)
    }

    object Map {
        val id: TypeDefinitionId = TypeDefinitionId(TypeId.Qualified("typewriter", "Map"), 1)
    }

    val list: TypeDefinitionId get() = List.id
    val set: TypeDefinitionId get() = Set.id
    val map: TypeDefinitionId get() = Map.id

    private val listItem = TypeParameter(ParameterKey(list, 0), "T")
    private val setItem = TypeParameter(ParameterKey(set, 0), "T")
    private val mapKey = TypeParameter(ParameterKey(map, 0), "K")
    private val mapValue = TypeParameter(ParameterKey(map, 1), "V")

    val definitions: kotlin.collections.List<TypeDefinition> =
        listOf(
            TypeDefinition(
                id = list,
                parameters = listOf(listItem),
                representation = RepresentationTemplate.Sequence(TypeTemplate.Parameter(listItem.key), CollectionKind.List),
            ),
            TypeDefinition(
                id = set,
                parameters = listOf(setItem),
                representation = RepresentationTemplate.Sequence(TypeTemplate.Parameter(setItem.key), CollectionKind.Set),
            ),
            TypeDefinition(
                id = map,
                parameters = listOf(mapKey, mapValue),
                representation =
                    RepresentationTemplate.Mapping(
                        TypeTemplate.Parameter(mapKey.key),
                        TypeTemplate.Parameter(mapValue.key),
                    ),
            ),
        )
}
