package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.Variance
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.codegen.isType
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.Resource
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceMatchTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

/** Namespace of the link types a `Ref<Endpoint, Target>` field resolves to. */
const val RELATION_LINK_NAMESPACE: String = "relation"

/** The link type of the generated endpoint interface named [endpointName]. */
fun relationLinkId(endpointName: String): TypeDefinitionId = TypeDefinitionId.qualified(RELATION_LINK_NAMESPACE, endpointName)

/**
 * The link definition of [endpoint]. It is generic over its target, which must be readable as a resource, unless the
 * opposite endpoint admits every resource of the definition [starOpposite]: then it takes no parameter and links to
 * that definition.
 */
fun relationLinkDefinition(
    endpointName: String,
    endpoint: EndpointId,
    starOpposite: TypeDefinitionId? = null,
): TypeDefinition {
    val id = relationLinkId(endpointName)
    if (starOpposite != null) {
        return TypeDefinition(
            id = id,
            parameters = emptyList(),
            representation =
                RepresentationTemplate.createLink(endpoint = endpoint, target = ResourceMatchTemplate.DefinitionWrapper(starOpposite)),
            parents = emptyList(),
        )
    }
    val target = ParameterKey(owner = id, index = 0)
    return TypeDefinition(
        id = id,
        parameters =
            listOf(
                TypeParameter(
                    key = target,
                    name = "Target",
                    bounds = listOf(RELATION_LINK_TARGET_BOUND.template(emptyList())),
                    derived = false,
                ),
            ),
        representation =
            RepresentationTemplate.createLink(
                endpoint = endpoint,
                target = ResourceMatchTemplate.TypeWrapper(target.template),
            ),
        parents = emptyList(),
    )
}

/** `Resource`, the bound of every link target, under the qualified Kotlin name its subtypes name as their parent. */
val RELATION_LINK_TARGET_BOUND: TypeDefinitionId = TypeDefinitionId.qualified("kotlin", checkNotNull(Resource::class.qualifiedName))

/** How a type's own arguments are stars: none of them, every one, or some beside written ones. */
enum class StarShape { NONE, EVERY, MIXED }

/** How this type's own arguments are stars; a type without arguments has none. */
fun KSType.starShape(): StarShape =
    when (arguments.count { it.variance == Variance.STAR }) {
        0 -> StarShape.NONE
        arguments.size -> StarShape.EVERY
        else -> StarShape.MIXED
    }

/**
 * The declaration whose every resource the opposite endpoint of this generated endpoint admits, whatever its
 * arguments, or null when the opposite endpoint names a type.
 */
fun KSClassDeclaration.starOpposite(): KSClassDeclaration? {
    val opposite =
        getAllSuperTypes()
            .firstOrNull { it.declaration isType RelationshipEndpoint::class.asClassName() }
            ?.arguments
            ?.getOrNull(1)
            ?.type
            ?.resolve() ?: return null
    return (opposite.declaration as? KSClassDeclaration)?.takeIf { opposite.starShape() == StarShape.EVERY }
}

/** This declaration with a star for every argument, as authors write it: `fixture.Board<*>`. */
fun KSClassDeclaration.starName(): String = "${qualifiedName?.asString() ?: simpleName.asString()}<${typeParameters.joinToString { "*" }}>"
