package com.typewritermc.types.ksp

import com.typewritermc.types.EndpointId
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate

/** Namespace of the link types a `Ref<Endpoint, Target>` field resolves to. */
const val RELATION_LINK_NAMESPACE: String = "relation"

/** The link type of the generated endpoint interface named [endpointName]. */
fun relationLinkId(endpointName: String): TypeDefinitionId = TypeDefinitionId(TypeId.Qualified(RELATION_LINK_NAMESPACE, endpointName), 1)

/** The link definition of [endpoint], generic over its target resource. */
fun relationLinkDefinition(
    endpointName: String,
    endpoint: EndpointId,
): TypeDefinition {
    val id = relationLinkId(endpointName)
    val target = ParameterKey(id, 0)
    return TypeDefinition(
        id,
        parameters = listOf(TypeParameter(target, "Target")),
        representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Parameter(target)),
    )
}
