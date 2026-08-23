package com.typewritermc.types.ksp

import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeAlias
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.symbol.Nullability
import com.google.devtools.ksp.symbol.Variance
import com.typewritermc.types.DataValue
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeVariance

/**
 * Converts compiler types into the portable Typewriter type graph used by manifests and transport adapters.
 *
 * Conversion discovers nominal declarations transitively and terminates recursive graphs through named references.
 * Callers may replace [identityPolicy] when annotations or artifact ownership define a more suitable public identity.
 * Unsupported compiler states are returned as diagnostics with the complete traversal path.
 */
class KspTypeGraphConverter(
    private val identityPolicy: KspTypeIdentityPolicy = QualifiedKotlinTypeIdentityPolicy,
) {
    fun convert(type: KSType): KspTypeConversionResult {
        val context = ConversionContext(identityPolicy)
        val root = context.expression(type, listOf(type.displayName))

        return if (root == null || context.diagnostics.isNotEmpty()) {
            KspTypeConversionResult.Failure(context.diagnostics.toList())
        } else {
            KspTypeConversionResult.Success(
                TypeGraph(
                    root = root,
                    definitions = context.definitions.values.sortedBy { it.id.sortKey },
                ),
            )
        }
    }
}

sealed interface KspTypeConversionResult {
    data class Success(
        val graph: TypeGraph,
    ) : KspTypeConversionResult

    data class Failure(
        val diagnostics: List<KspTypeDiagnostic>,
    ) : KspTypeConversionResult
}

data class KspTypeDiagnostic(
    val path: List<String>,
    val message: String,
) {
    override fun toString(): String = "${path.joinToString(" -> ")}: $message"
}

fun interface KspTypeIdentityPolicy {
    fun identity(declaration: KSClassDeclaration): ResolvedTypeRef
}

object QualifiedKotlinTypeIdentityPolicy : KspTypeIdentityPolicy {
    override fun identity(declaration: KSClassDeclaration): ResolvedTypeRef {
        val packageName = declaration.packageName.asString()
        require(packageName.isNotBlank()) { "Types in the root package require a custom KSP type identity policy." }
        val qualifiedName = requireNotNull(declaration.qualifiedName).asString()
        val relativeName = qualifiedName.removePrefix("$packageName.")
        return ResolvedTypeRef(TypeId.Qualified(packageName, relativeName), revision = 1)
    }
}

private class ConversionContext(
    private val identityPolicy: KspTypeIdentityPolicy,
) {
    val definitions = linkedMapOf<ResolvedTypeRef, TypeDefinition>()
    val diagnostics = mutableListOf<KspTypeDiagnostic>()
    private val visiting = mutableSetOf<ResolvedTypeRef>()

    fun expression(
        type: KSType,
        path: List<String>,
    ): TypeExpression? {
        if (type.isError) return failure(path, "KSP could not resolve this type.")
        if (type.isFunctionType || type.isSuspendFunctionType) {
            return failure(path, "Function types do not have a Typewriter data representation.")
        }

        val expression = nonNullableExpression(type, path) ?: return null
        return if (type.nullability == Nullability.NULLABLE || type.nullability == Nullability.PLATFORM) {
            StandardTypes.definitions.take(3).forEach { definitions.putIfAbsent(it.id, it) }
            TypeExpression.Named(StandardTypes.optionOf(expression))
        } else {
            expression
        }
    }

    private fun nonNullableExpression(
        type: KSType,
        path: List<String>,
    ): TypeExpression? {
        val declaration = type.declaration
        if (declaration is KSTypeParameter) return TypeExpression.Parameter(declaration.name.asString())
        if (declaration is KSTypeAlias) return alias(type, declaration, path)
        val classDeclaration =
            declaration as? KSClassDeclaration
                ?: return failure(path, "Unsupported KSP declaration ${declaration::class.simpleName}.")
        val qualifiedName =
            classDeclaration.qualifiedName?.asString()
                ?: return failure(path, "Local and anonymous types require an explicit nominal identity.")

        primitive(qualifiedName)?.let { return it }
        collection(type, qualifiedName, path)?.let { return it }
        return nominal(type, classDeclaration, path)
    }

    private fun alias(
        type: KSType,
        declaration: KSTypeAlias,
        path: List<String>,
    ): TypeExpression? {
        val target = declaration.type.resolve()
        val resolved = if (target.arguments.size == type.arguments.size) target.replace(type.arguments) else target
        return expression(resolved, path + "alias ${declaration.name.asString()}")
    }

    private fun collection(
        type: KSType,
        qualifiedName: String,
        path: List<String>,
    ): TypeExpression? =
        when (qualifiedName) {
            "kotlin.ByteArray" -> TypeExpression.Bytes()

            in PRIMITIVE_ARRAYS -> TypeExpression.ListType(requireNotNull(primitive(PRIMITIVE_ARRAYS.getValue(qualifiedName))))

            "kotlin.Array",
            "kotlin.collections.ArrayList",
            "kotlin.collections.Collection",
            "kotlin.collections.Iterable",
            "kotlin.collections.List",
            "kotlin.collections.MutableCollection",
            "kotlin.collections.MutableIterable",
            "kotlin.collections.MutableList",
            -> TypeExpression.ListType(argument(type, 0, path))

            "kotlin.collections.HashSet",
            "kotlin.collections.LinkedHashSet",
            "kotlin.collections.MutableSet",
            "kotlin.collections.Set",
            -> TypeExpression.ListType(argument(type, 0, path), unique = true)

            "kotlin.collections.HashMap",
            "kotlin.collections.LinkedHashMap",
            "kotlin.collections.Map",
            "kotlin.collections.MutableMap",
            -> TypeExpression.MapType(argument(type, 0, path), argument(type, 1, path))

            else -> null
        }

    private fun argument(
        type: KSType,
        index: Int,
        path: List<String>,
    ): TypeExpression {
        val reference = type.arguments.getOrNull(index)?.type ?: return TypeExpression.Any
        return expression(reference.resolve(), path + "argument $index") ?: TypeExpression.Any
    }

    private fun nominal(
        type: KSType,
        declaration: KSClassDeclaration,
        path: List<String>,
    ): TypeExpression? {
        val identity =
            runCatching { identityPolicy.identity(declaration) }
                .getOrElse { return failure(path, it.message ?: "Could not assign a Typewriter identity.") }
        val arguments =
            type.arguments.mapIndexed { index, argument ->
                argument.type?.resolve()?.let { expression(it, path + "argument $index") } ?: TypeExpression.Any
            }
        val reference = identity.withArguments(arguments.filterNotNull())
        if (identity !in definitions && visiting.add(identity)) {
            buildDefinition(declaration, identity, path)
            visiting.remove(identity)
        }
        return TypeExpression.Named(reference)
    }

    private fun buildDefinition(
        declaration: KSClassDeclaration,
        identity: ResolvedTypeRef,
        path: List<String>,
    ) {
        val definitionPath = path + identity.sortKey
        val parameters = declaration.typeParameters.map { parameter(it, definitionPath) }
        val parents =
            declaration.superTypes
                .mapNotNull { reference ->
                    val parentType = reference.resolve()
                    if (parentType.declaration.qualifiedName?.asString() == "kotlin.Any") return@mapNotNull null
                    (expression(parentType, definitionPath + "supertype") as? TypeExpression.Named)?.reference
                        ?: failure(definitionPath, "A nominal supertype did not convert to a named reference.")
                }.toList()
        val representation =
            when (declaration.classKind) {
                ClassKind.ENUM_CLASS -> enumRepresentation(declaration, definitionPath)
                ClassKind.ENUM_ENTRY -> TypeExpression.Unit
                else -> recordRepresentation(declaration, definitionPath)
            }
        definitions[identity] =
            TypeDefinition(
                id = identity,
                kind = declaration.nominalKind,
                representation = representation,
                parameters = parameters,
                parents = parents,
            )
        if (Modifier.SEALED in declaration.modifiers) {
            declaration.getSealedSubclasses().forEach { child ->
                nominal(child.asStarProjectedType(), child, definitionPath + "sealed subtype ${child.simpleName.asString()}")
            }
        }
    }

    private fun parameter(
        parameter: KSTypeParameter,
        path: List<String>,
    ): TypeParameter {
        val bounds =
            parameter.bounds
                .mapNotNull { reference ->
                    val type = reference.resolve()
                    if (type.declaration.qualifiedName?.asString() ==
                        "kotlin.Any"
                    ) {
                        null
                    } else {
                        expression(type, path + parameter.name.asString())
                    }
                }.toList()
        return TypeParameter(
            name = parameter.name.asString(),
            upperBounds = bounds,
            variance =
                when (parameter.variance) {
                    Variance.INVARIANT -> TypeVariance.INVARIANT
                    Variance.COVARIANT -> TypeVariance.COVARIANT
                    Variance.CONTRAVARIANT -> TypeVariance.CONTRAVARIANT
                    Variance.STAR -> TypeVariance.INVARIANT
                },
        )
    }

    private fun recordRepresentation(
        declaration: KSClassDeclaration,
        path: List<String>,
    ): TypeExpression {
        val fields =
            declaration
                .getAllProperties()
                .filter(KSPropertyDeclaration::isSerializedProperty)
                .mapNotNull { property ->
                    val name = property.serialName ?: property.simpleName.asString()
                    expression(property.type.resolve(), path + name)?.let { TypeField(name, it) }
                }.sortedBy(TypeField::name)
                .toList()
        return if (declaration.classKind == ClassKind.OBJECT && fields.isEmpty()) {
            TypeExpression.Unit
        } else {
            TypeExpression.Record(fields)
        }
    }

    private fun enumRepresentation(
        declaration: KSClassDeclaration,
        path: List<String>,
    ): TypeExpression {
        val values =
            declaration.declarations
                .filterIsInstance<KSClassDeclaration>()
                .filter { it.classKind == ClassKind.ENUM_ENTRY }
                .map { DataValue.StringValue(it.serialName ?: it.simpleName.asString()) }
                .toList()
        if (values.isEmpty()) failure(path, "Enum declarations must contain at least one entry.")
        return TypeExpression.Enumeration(TypeExpression.StringType(), values.ifEmpty { listOf(DataValue.StringValue("UNKNOWN")) })
    }

    private fun primitive(qualifiedName: String): TypeExpression? =
        when (qualifiedName) {
            "kotlin.Any" -> TypeExpression.Any
            "kotlin.Unit" -> TypeExpression.Unit
            "kotlin.Boolean" -> TypeExpression.Boolean
            "kotlin.String" -> TypeExpression.StringType()
            "kotlin.Char" -> TypeExpression.StringType(minimumLength = 1, maximumLength = 1)
            "kotlin.Byte" -> TypeExpression.Integer(IntegerWidth.SIGNED_8)
            "kotlin.Short" -> TypeExpression.Integer(IntegerWidth.SIGNED_16)
            "kotlin.Int" -> TypeExpression.Integer(IntegerWidth.SIGNED_32)
            "kotlin.Long" -> TypeExpression.Integer(IntegerWidth.SIGNED_64)
            "kotlin.UByte" -> TypeExpression.Integer(IntegerWidth.UNSIGNED_8)
            "kotlin.UShort" -> TypeExpression.Integer(IntegerWidth.UNSIGNED_16)
            "kotlin.UInt" -> TypeExpression.Integer(IntegerWidth.UNSIGNED_32)
            "kotlin.ULong" -> TypeExpression.Integer(IntegerWidth.UNSIGNED_64)
            "java.math.BigInteger" -> TypeExpression.Integer(IntegerWidth.SIGNED_64)
            "kotlin.Float" -> TypeExpression.Float(FloatWidth.FLOAT_32)
            "kotlin.Double" -> TypeExpression.Float(FloatWidth.FLOAT_64)
            "kotlin.time.Instant", "java.time.Instant" -> TypeExpression.Timestamp()
            "kotlin.time.Duration", "java.time.Duration" -> TypeExpression.Duration()
            else -> null
        }

    private fun failure(
        path: List<String>,
        message: String,
    ): Nothing? {
        diagnostics += KspTypeDiagnostic(path, message)
        return null
    }
}

private val KSClassDeclaration.nominalKind: NominalTypeKind
    get() =
        when {
            Modifier.SEALED in modifiers -> NominalTypeKind.SEALED_ABSTRACT
            classKind == ClassKind.INTERFACE || Modifier.ABSTRACT in modifiers -> NominalTypeKind.OPEN_ABSTRACT
            else -> NominalTypeKind.CONCRETE
        }

private val KSType.displayName: String
    get() = declaration.qualifiedName?.asString() ?: declaration.simpleName.asString()

private val KSDeclaration.serialName: String?
    get() =
        annotations
            .firstOrNull {
                it.annotationType
                    .resolve()
                    .declaration.qualifiedName
                    ?.asString() == "kotlinx.serialization.SerialName"
            }?.arguments
            ?.firstOrNull { it.name?.asString() == "value" }
            ?.value as? String

private fun KSDeclaration.hasAnnotation(qualifiedName: String): Boolean =
    annotations.any {
        it.annotationType
            .resolve()
            .declaration
            .qualifiedName
            ?.asString() == qualifiedName
    }

private val KSPropertyDeclaration.isSerializedProperty: Boolean
    get() =
        extensionReceiver == null &&
            hasBackingField &&
            !isDelegated() &&
            !hasAnnotation("kotlinx.serialization.Transient")

private val ResolvedTypeRef.sortKey: String
    get() =
        when (val typeId = id) {
            is TypeId.Builtin -> "builtin::${typeId.id}@$revision"
            is TypeId.Declared -> "declared::${typeId.id}@$revision"
            is TypeId.Qualified -> "${typeId.namespace}::${typeId.name}@$revision"
        }

private val PRIMITIVE_ARRAYS =
    mapOf(
        "kotlin.BooleanArray" to "kotlin.Boolean",
        "kotlin.CharArray" to "kotlin.Char",
        "kotlin.DoubleArray" to "kotlin.Double",
        "kotlin.FloatArray" to "kotlin.Float",
        "kotlin.IntArray" to "kotlin.Int",
        "kotlin.LongArray" to "kotlin.Long",
        "kotlin.ShortArray" to "kotlin.Short",
        "kotlin.UByteArray" to "kotlin.UByte",
        "kotlin.UIntArray" to "kotlin.UInt",
        "kotlin.ULongArray" to "kotlin.ULong",
        "kotlin.UShortArray" to "kotlin.UShort",
    )
