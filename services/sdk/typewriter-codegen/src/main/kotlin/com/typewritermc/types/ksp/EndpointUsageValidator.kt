package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSNode
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.codegen.KnownTypes
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.isOneOf
import com.typewritermc.codegen.isType
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationshipEndpoint
import com.typewritermc.types.TypewriterGeneratedEndpoint
import com.typewritermc.types.TypewriterString

data class EndpointUsageDiagnostic(
    val symbol: KSNode,
    val message: String,
)

class EndpointUsageValidator {
    fun validate(resource: KSClassDeclaration): List<EndpointUsageDiagnostic> {
        val walk = ResourceWalk(resource.asStarProjectedType())
        walk.visit(
            type = walk.resource,
            symbol = resource,
            path = listOf(resource.simpleName.asString()),
            containsCollection = false,
            stack = emptySet(),
        )
        return walk.diagnostics
    }
}

/** Walks the authorable fields of [resource], collecting a diagnostic for each relation endpoint used where it does not fit. */
private class ResourceWalk(
    val resource: KSType,
) {
    val diagnostics = mutableListOf<EndpointUsageDiagnostic>()

    fun visit(
        type: KSType,
        symbol: KSNode,
        path: List<String>,
        containsCollection: Boolean,
        stack: Set<String>,
    ) {
        val declaration = type.declaration
        val qualified = declaration.qualifiedName?.asString() ?: return
        when {
            declaration isType Ref::class.asClassName() -> {
                validateReference(type, symbol, path, containsCollection)
            }

            declaration isOneOf KnownTypes.containers -> {
                type.arguments.forEachIndexed { index, argument ->
                    argument.type?.resolve()?.let { item ->
                        visit(item, symbol, path + "argument $index", true, stack)
                    }
                }
            }

            declaration isOneOf KnownTypes.terminals -> {
                Unit
            }

            declaration is KSClassDeclaration && declaration.isTerminalDeclaration() -> {
                Unit
            }

            declaration is KSClassDeclaration -> {
                val key = qualified
                if (key in stack) return
                val nestedStack = stack + key
                declaration.getAllProperties().filter(KSPropertyDeclaration::isAuthorable).forEach { property ->
                    val propertyType = runCatching { property.asMemberOf(type) }.getOrElse { property.type.resolve() }
                    visit(propertyType, property, path + property.simpleName.asString(), containsCollection, nestedStack)
                }
            }
        }
    }

    private fun validateReference(
        reference: KSType,
        symbol: KSNode,
        path: List<String>,
        containsCollection: Boolean,
    ) {
        val endpoint =
            reference.arguments
                .getOrNull(0)
                ?.type
                ?.resolve() ?: return
        val target =
            reference.arguments
                .getOrNull(1)
                ?.type
                ?.resolve() ?: return
        val endpointDeclaration = endpoint.declaration as? KSClassDeclaration ?: return
        val contract =
            endpointDeclaration
                .getAllSuperTypes()
                .firstOrNull { supertype ->
                    supertype.declaration isType RelationshipEndpoint::class.asClassName()
                } ?: return
        val expectedSource =
            contract.arguments
                .getOrNull(0)
                ?.type
                ?.resolve() ?: return
        val expectedTarget =
            contract.arguments
                .getOrNull(1)
                ?.type
                ?.resolve() ?: return
        val endpointName = endpointDeclaration.qualifiedName?.asString() ?: endpointDeclaration.simpleName.asString()
        val requiresCollection = endpointDeclaration.annotation<TypewriterGeneratedEndpoint>()?.requiresCollection
        if (requiresCollection != null && requiresCollection != containsCollection) {
            val requirement = if (requiresCollection) "requires" else "forbids"
            diagnostics +=
                EndpointUsageDiagnostic(
                    symbol,
                    "${path.joinToString(".")}: Relation endpoint $endpointName $requirement a collection on its containing field path.",
                )
        }
        if (!expectedSource.acceptsEvery(resource)) {
            diagnostics +=
                EndpointUsageDiagnostic(
                    symbol,
                    "${path.joinToString(".")}: Relation endpoint $endpointName does not accept source ${resource.displayName()}.",
                )
        }
        if (!expectedTarget.acceptsEvery(target)) {
            diagnostics +=
                EndpointUsageDiagnostic(
                    symbol,
                    "${path.joinToString(".")}: Relation endpoint $endpointName does not accept target ${target.displayName()}.",
                )
        }
    }
}

private fun KSType.acceptsEvery(actual: KSType): Boolean {
    val parameter = actual.declaration as? KSTypeParameter
    if (parameter != null) {
        val bounds = parameter.bounds.map { it.resolve() }.toList()
        return bounds.any(::acceptsEvery)
    }
    if (
        declaration.qualifiedName?.asString() == actual.declaration.qualifiedName?.asString() &&
        arguments.size == actual.arguments.size
    ) {
        return arguments.zip(actual.arguments).all { (expected, supplied) ->
            val expectedType = expected.type?.resolve() ?: return@all true
            val suppliedType = supplied.type?.resolve() ?: return@all false
            expectedType.acceptsEvery(suppliedType)
        }
    }
    return isAssignableFrom(actual)
}

private fun KSType.displayName(): String = declaration.qualifiedName?.asString() ?: declaration.simpleName.asString()

private fun KSClassDeclaration.isTerminalDeclaration(): Boolean =
    classKind == ClassKind.ENUM_CLASS ||
        classKind == ClassKind.ENUM_ENTRY ||
        Modifier.VALUE in modifiers ||
        annotation<TypewriterString>() != null

private fun KSPropertyDeclaration.isAuthorable(): Boolean = isStoredTypeProperty
