package com.typewritermc.types

object StandardTypes {
    val list = TypeDefinitionId(TypeId.Qualified("typewriter", "List"), 1)
    val set = TypeDefinitionId(TypeId.Qualified("typewriter", "Set"), 1)
    val map = TypeDefinitionId(TypeId.Qualified("typewriter", "Map"), 1)

    private val listItem = TypeParameter(ParameterKey(list, 0), "T")
    private val setItem = TypeParameter(ParameterKey(set, 0), "T")
    private val mapKey = TypeParameter(ParameterKey(map, 0), "K")
    private val mapValue = TypeParameter(ParameterKey(map, 1), "V")

    val definitions: List<TypeDefinition> =
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
