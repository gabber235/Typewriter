package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSNode
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier

data class EndpointUsageDiagnostic(
    val symbol: KSNode,
    val message: String,
)

class EndpointUsageValidator {
    fun validate(resource: KSClassDeclaration): List<EndpointUsageDiagnostic> {
        val diagnostics = mutableListOf<EndpointUsageDiagnostic>()
        val resourceType = resource.asStarProjectedType()
        visit(
            type = resourceType,
            resource = resourceType,
            symbol = resource,
            path = listOf(resource.simpleName.asString()),
            containsCollection = false,
            stack = emptySet(),
            diagnostics = diagnostics,
        )
        return diagnostics
    }

    private fun visit(
        type: KSType,
        resource: KSType,
        symbol: KSNode,
        path: List<String>,
        containsCollection: Boolean,
        stack: Set<String>,
        diagnostics: MutableList<EndpointUsageDiagnostic>,
    ) {
        val declaration = type.declaration
        val qualified = declaration.qualifiedName?.asString() ?: return
        when {
            qualified == REFERENCE_TYPE -> {
                validateReference(type, resource, symbol, path, containsCollection, diagnostics)
            }

            qualified in COLLECTION_TYPES -> {
                type.arguments.forEachIndexed { index, argument ->
                    argument.type?.resolve()?.let { item ->
                        visit(item, resource, symbol, path + "argument $index", true, stack, diagnostics)
                    }
                }
            }

            qualified in TERMINAL_TYPES -> {
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
                    visit(
                        propertyType,
                        resource,
                        property,
                        path + property.simpleName.asString(),
                        containsCollection,
                        nestedStack,
                        diagnostics,
                    )
                }
            }
        }
    }

    private fun validateReference(
        reference: KSType,
        resource: KSType,
        symbol: KSNode,
        path: List<String>,
        containsCollection: Boolean,
        diagnostics: MutableList<EndpointUsageDiagnostic>,
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
                    supertype.declaration.qualifiedName?.asString() == RELATIONSHIP_ENDPOINT_TYPE
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
        val requiresCollection =
            endpointDeclaration
                .annotation(GENERATED_ENDPOINT_ANNOTATION)
                ?.argument("requiresCollection") as? Boolean
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
        hasAnnotation(TYPEWRITER_STRING_ANNOTATION)

private fun KSPropertyDeclaration.isAuthorable(): Boolean = isStoredTypeProperty

private fun KSAnnotated.hasAnnotation(qualifiedName: String): Boolean =
    annotations.any { annotation ->
        annotation.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun KSAnnotated.annotation(qualifiedName: String) =
    annotations.firstOrNull { annotation ->
        annotation.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun com.google.devtools.ksp.symbol.KSAnnotation.argument(name: String): Any? =
    arguments.firstOrNull { it.name?.asString() == name }?.value

private const val REFERENCE_TYPE = "com.typewritermc.types.Ref"
private const val RELATIONSHIP_ENDPOINT_TYPE = "com.typewritermc.types.RelationshipEndpoint"
private const val GENERATED_ENDPOINT_ANNOTATION = "com.typewritermc.types.TypewriterGeneratedEndpoint"
private const val TYPEWRITER_STRING_ANNOTATION = "com.typewritermc.types.TypewriterString"

private val COLLECTION_TYPES =
    setOf(
        "kotlin.Array",
        "kotlin.collections.Collection",
        "kotlin.collections.Iterable",
        "kotlin.collections.List",
        "kotlin.collections.Map",
        "kotlin.collections.MutableCollection",
        "kotlin.collections.MutableIterable",
        "kotlin.collections.MutableList",
        "kotlin.collections.MutableMap",
        "kotlin.collections.MutableSet",
        "kotlin.collections.Set",
    )

private val TERMINAL_TYPES =
    setOf(
        "kotlin.Any",
        "kotlin.Boolean",
        "kotlin.Byte",
        "kotlin.Double",
        "kotlin.Float",
        "kotlin.Int",
        "kotlin.Long",
        "kotlin.Short",
        "kotlin.String",
        "kotlin.UByte",
        "kotlin.UInt",
        "kotlin.ULong",
        "kotlin.UShort",
        "kotlin.Unit",
        "kotlin.time.Duration",
        "kotlin.time.Instant",
        "java.math.BigDecimal",
        "java.math.BigInteger",
    )
