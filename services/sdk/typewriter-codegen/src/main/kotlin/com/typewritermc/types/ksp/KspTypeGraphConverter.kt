package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.FileLocation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeAlias
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.symbol.Nullability
import com.google.devtools.ksp.symbol.Variance
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldMergePolicy
import com.typewritermc.types.FieldMergeStrategy
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
    /**
     * Converts [type] and every reachable nominal declaration into one self contained graph.
     *
     * Recursive visits become named references. Nullable values become the standard Option representation. A
     * failure never returns a partial graph, and diagnostics identify the path through fields, aliases, supertypes,
     * and generic arguments that led to the unsupported compiler state.
     */
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
                context.serializedProperties.sortedWith(
                    compareBy<KspSerializedProperty> { it.ownerType.sortKey }.thenBy(KspSerializedProperty::serializedName),
                ),
                context.declarations.toMap(),
            )
        }
    }
}

/**
 * Outcome of compiler type traversal. Success contains the complete portable graph; failure retains traversal
 * diagnostics instead of exposing a partially usable schema. Exceptions from a custom identity policy are not
 * represented by this result.
 */
sealed interface KspTypeConversionResult {
    data class Success(
        val graph: TypeGraph,
        val serializedProperties: List<KspSerializedProperty>,
        val declarations: Map<ResolvedTypeRef, KSClassDeclaration>,
    ) : KspTypeConversionResult

    data class Failure(
        val diagnostics: List<KspTypeDiagnostic>,
    ) : KspTypeConversionResult
}

/** Connects one structural record field back to the Kotlin property that supplied its serialization metadata. */
data class KspSerializedProperty(
    val ownerType: ResolvedTypeRef,
    val serializedName: String,
    val declaration: KSPropertyDeclaration,
)

/**
 * Unsupported compiler type or declaration encountered during graph traversal. The path records the route from the
 * requested root to the failure, making nested generic and field errors actionable at the source declaration.
 */
data class KspTypeDiagnostic(
    val path: List<String>,
    val message: String,
) {
    override fun toString(): String = "${path.joinToString(" -> ")}: $message"
}

/**
 * Assigns stable nominal references while compiler declarations become a portable graph. Implementations define
 * namespace and revision policy and must return consistent identities for repeated visits to the same declaration.
 * Annotations can supply public identity independently of Kotlin package layout.
 */
fun interface KspTypeIdentityPolicy {
    fun identity(declaration: KSClassDeclaration): ResolvedTypeRef
}

/**
 * Default nominal identity derived from the Kotlin package and relative declaration name at revision one. Root
 * package and anonymous declarations cannot supply the required qualified identity and fail conversion. Use an
 * explicit policy when renaming Kotlin declarations must preserve public schema identity.
 */
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
    val declarations = linkedMapOf<ResolvedTypeRef, KSClassDeclaration>()
    val diagnostics = mutableListOf<KspTypeDiagnostic>()
    val serializedProperties = mutableListOf<KspSerializedProperty>()
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

        if (qualifiedName == REF_TYPE) return reference(type, path)
        if (qualifiedName == TO_ONE_TYPE) return relationReference(type, path, many = false)
        if (qualifiedName == TO_MANY_TYPE) return relationReference(type, path, many = true)
        if (classDeclaration.hasAnnotation(TYPEWRITER_STRING_ANNOTATION)) {
            return logicalString(type, classDeclaration, path)
        }
        primitive(qualifiedName)?.let { return it }
        collection(type, qualifiedName, path)?.let { return it }
        return nominal(type, classDeclaration, path)
    }

    private fun reference(
        type: KSType,
        path: List<String>,
    ): TypeExpression? {
        if (type.arguments.size != 1) return failure(path, "Ref requires exactly one target type argument.")
        val targetType =
            type.arguments
                .single()
                .type
                ?.resolve() ?: return failure(path, "Ref target cannot be a star projection.")
        val targetDeclaration =
            targetType.declaration as? KSClassDeclaration
                ?: return failure(path, "Ref target must be a nominal type.")
        val referenceable =
            targetDeclaration.qualifiedName?.asString() == REFERENCEABLE_TYPE ||
                targetDeclaration.getAllSuperTypes().any {
                    it.declaration.qualifiedName?.asString() == REFERENCEABLE_TYPE
                }
        if (!referenceable) return failure(path, "Ref target must inherit Referenceable.")
        val target =
            expression(targetType, path + "reference target") as? TypeExpression.Named
                ?: return failure(path, "Ref target must resolve to a named type.")
        return TypeExpression.Reference(target.reference)
    }

    private fun relationReference(
        type: KSType,
        path: List<String>,
        many: Boolean,
    ): TypeExpression? {
        if (type.arguments.size != 2) return failure(path, "Relation endpoints require marker and target type arguments.")
        val targetType =
            type.arguments[1].type?.resolve()
                ?: return failure(path, "Relation endpoint target cannot be a star projection.")
        val targetDeclaration =
            targetType.declaration as? KSClassDeclaration
                ?: return failure(path, "Relation endpoint target must be a nominal type.")
        val referenceable =
            targetDeclaration.qualifiedName?.asString() == REFERENCEABLE_TYPE ||
                targetDeclaration.getAllSuperTypes().any {
                    it.declaration.qualifiedName?.asString() == REFERENCEABLE_TYPE
                }
        if (!referenceable) return failure(path, "Relation endpoint target must inherit Referenceable.")
        val target =
            expression(targetType, path + "relation target") as? TypeExpression.Named
                ?: return failure(path, "Relation endpoint target must resolve to a named type.")
        val reference = TypeExpression.Reference(target.reference)
        return if (many) TypeExpression.ListType(reference, unique = true) else reference
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
            runCatching { identity(declaration) }
                .getOrElse { return failure(path, it.message ?: "Could not assign a Typewriter identity.") }
        declarations.putIfAbsent(identity, declaration)
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

    private fun logicalString(
        type: KSType,
        declaration: KSClassDeclaration,
        path: List<String>,
    ): TypeExpression? {
        val identity =
            runCatching { identity(declaration) }
                .getOrElse { return failure(path, it.message ?: "Could not assign a Typewriter identity.") }
        declarations.putIfAbsent(identity, declaration)
        val arguments =
            type.arguments.mapIndexed { index, argument ->
                argument.type?.resolve()?.let { expression(it, path + "argument $index") } ?: TypeExpression.Any
            }
        if (identity !in definitions) {
            definitions[identity] =
                TypeDefinition(
                    id = identity,
                    kind = NominalTypeKind.CONCRETE,
                    displayName = declaration.simpleName.asString(),
                    qualifiedName = declaration.qualifiedName?.asString(),
                    declarationOwner = declaration.packageName.asString(),
                    representation = TypeExpression.StringType(),
                    parameters = declaration.typeParameters.map { parameter(it, path + identity.sortKey) },
                )
        }
        return TypeExpression.Named(identity.withArguments(arguments.filterNotNull()))
    }

    private fun identity(declaration: KSClassDeclaration): ResolvedTypeRef = identityPolicy.identity(declaration)

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
                else if (declaration.isValueClass) -> valueClassRepresentation(declaration, definitionPath)
                else -> recordRepresentation(declaration, identity, definitionPath)
            }
        val mergePolicies =
            if (representation is TypeExpression.Record) {
                orderedSerializedProperties(declaration).mapNotNull { property ->
                    if (!property.type.resolve().isSetCollection()) return@mapNotNull null
                    val serializedName = property.serialName ?: property.simpleName.asString()
                    FieldMergePolicy(DataPath.field(serializedName), FieldMergeStrategy.SET_MEMBERSHIP)
                }
            } else {
                emptyList()
            }
        definitions[identity] =
            TypeDefinition(
                id = identity,
                kind = declaration.nominalKind,
                displayName = declaration.simpleName.asString(),
                qualifiedName = declaration.qualifiedName?.asString(),
                declarationOwner = declaration.packageName.asString(),
                representation = representation,
                parameters = parameters,
                parents = parents,
                fieldMergePolicies = mergePolicies,
            )
        if (Modifier.SEALED in declaration.modifiers) {
            declaration.getSealedSubclasses().forEach { child ->
                nominal(child.asStarProjectedType(), child, definitionPath + "sealed subtype ${child.simpleName.asString()}")
            }
        }
    }

    private fun valueClassRepresentation(
        declaration: KSClassDeclaration,
        path: List<String>,
    ): TypeExpression {
        val parameter =
            declaration.primaryConstructor?.parameters?.singleOrNull()
                ?: return failure(path, "A value class must have exactly one primary constructor parameter.")
                    ?: TypeExpression.Unit
        return expression(parameter.type.resolve(), path + (parameter.name?.asString() ?: "value"))
            ?: TypeExpression.Unit
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
        identity: ResolvedTypeRef,
        path: List<String>,
    ): TypeExpression {
        val fields =
            orderedSerializedProperties(declaration)
                .mapNotNull { property ->
                    val name = property.serialName ?: property.simpleName.asString()
                    expression(property.type.resolve(), path + name)?.let {
                        serializedProperties += KspSerializedProperty(identity, name, property)
                        TypeField(
                            name = name,
                            type = it,
                            defaulted = property.hasConstructorDefault,
                        )
                    }
                }
        return if (declaration.classKind == ClassKind.OBJECT && fields.isEmpty()) {
            TypeExpression.Unit
        } else {
            TypeExpression.Record(fields)
        }
    }

    /**
     * Orders fields by Kotlin declaration semantics instead of relying on the unspecified order of [getAllProperties].
     * Inherited declarations come first, followed by constructor properties and then properties declared in the
     * class body. Body properties use source line locations when available. Any remaining compiler properties are
     * appended in the order returned by KSP.
     */
    private fun orderedSerializedProperties(declaration: KSClassDeclaration): List<KSPropertyDeclaration> {
        val properties = declaration.getAllProperties().filter(KSPropertyDeclaration::isSerializedProperty).toList()
        val propertiesByName = properties.associateBy { it.simpleName.asString() }
        val orderedNames = linkedSetOf<String>()
        val visited = mutableSetOf<KSClassDeclaration>()

        fun append(name: String?) {
            if (name != null && name in propertiesByName) orderedNames += name
        }

        fun appendDeclarations(current: KSClassDeclaration) {
            if (!visited.add(current)) return

            current.superTypes
                .mapNotNull { reference -> reference.resolve().declaration as? KSClassDeclaration }
                .forEach(::appendDeclarations)
            current.primaryConstructor?.parameters?.forEach { parameter ->
                append(parameter.name?.asString())
            }
            current.declarations
                .filterIsInstance<KSPropertyDeclaration>()
                .filter(KSPropertyDeclaration::isSerializedProperty)
                .withIndex()
                .sortedWith(
                    compareBy<IndexedValue<KSPropertyDeclaration>> {
                        (it.value.location as? FileLocation)?.filePath ?: "\uFFFF"
                    }.thenBy {
                        (it.value.location as? FileLocation)?.lineNumber ?: Int.MAX_VALUE
                    }.thenBy(IndexedValue<KSPropertyDeclaration>::index),
                ).map(IndexedValue<KSPropertyDeclaration>::value)
                .forEach { property -> append(property.simpleName.asString()) }
        }

        appendDeclarations(declaration)
        properties.forEach { property -> append(property.simpleName.asString()) }
        return orderedNames.mapNotNull(propertiesByName::get)
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

private val KSClassDeclaration.isValueClass: Boolean
    get() = Modifier.VALUE in modifiers || hasAnnotation("kotlin.jvm.JvmInline")

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
            (hasBackingField || isConstructorProperty) &&
            !isDelegated() &&
            !hasAnnotation("kotlinx.serialization.Transient")

private val KSPropertyDeclaration.isConstructorProperty: Boolean
    get() {
        val owner = parentDeclaration as? KSClassDeclaration ?: return false
        val name = simpleName.asString()
        return owner.primaryConstructor?.parameters?.any { parameter ->
            parameter.name?.asString() == name && (parameter.isVal || parameter.isVar)
        } == true
    }

private val KSPropertyDeclaration.hasConstructorDefault: Boolean
    get() {
        val owner = parentDeclaration as? KSClassDeclaration ?: return false
        val name = simpleName.asString()
        return owner.primaryConstructor
            ?.parameters
            ?.firstOrNull { parameter ->
                parameter.name?.asString() == name && (parameter.isVal || parameter.isVar)
            }?.hasDefault == true
    }

private fun KSType.isSetCollection(): Boolean {
    val qualifiedName = (declaration as? KSClassDeclaration)?.qualifiedName?.asString() ?: return false
    return qualifiedName in
        setOf(
            "kotlin.collections.HashSet",
            "kotlin.collections.LinkedHashSet",
            "kotlin.collections.MutableSet",
            "kotlin.collections.Set",
        )
}

private val ResolvedTypeRef.sortKey: String
    get() =
        when (val typeId = id) {
            is TypeId.Builtin -> "builtin::${typeId.id}@$revision"
            is TypeId.Declared -> "declared::${typeId.id}@$revision"
            is TypeId.Qualified -> "${typeId.namespace}::${typeId.name}@$revision"
        }

private const val TYPEWRITER_STRING_ANNOTATION = "com.typewritermc.types.TypewriterString"
private const val REF_TYPE = "com.typewritermc.types.Ref"
private const val TO_ONE_TYPE = "com.typewritermc.types.ToOne"
private const val TO_MANY_TYPE = "com.typewritermc.types.ToMany"
private const val REFERENCEABLE_TYPE = "com.typewritermc.types.Referenceable"

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
