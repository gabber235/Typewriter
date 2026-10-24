package com.typewritermc.types.ksp

import com.typewritermc.types.qualified
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

/** Namespace of the link types a `Ref<Endpoint, Target>` field resolves to. */
const val RELATION_LINK_NAMESPACE: String = "relation"

/** The link type of the generated endpoint interface named [endpointName]. */
fun relationLinkId(endpointName: String): TypeDefinitionId = TypeDefinitionId.qualified(RELATION_LINK_NAMESPACE, endpointName)

/** The link definition of [endpoint], generic over its target resource. */
fun relationLinkDefinition(
    endpointName: String,
    endpoint: EndpointId,
): TypeDefinition {
    val id = relationLinkId(endpointName)
    val target = ParameterKey(owner = id, index = 0)
    return TypeDefinition(
        id = id,
        parameters = listOf(TypeParameter(key = target, name = "Target", bounds = emptyList())),
        representation = RepresentationTemplate.createLink(endpoint = endpoint, target = target.template),
        parents = emptyList(),
    )
}
