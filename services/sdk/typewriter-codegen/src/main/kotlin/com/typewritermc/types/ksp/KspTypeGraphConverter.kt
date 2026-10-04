package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EnumVariant
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse

fun interface KspTypeIdentityPolicy {
    fun identity(declaration: KSClassDeclaration): TypeDefinitionId
}

fun interface KspLinkPolicy {
    fun endpoint(endpoint: KSClassDeclaration): EndpointId?
}

data class OwnedFieldDeclaration(
    val owner: TypeDefinitionId,
    val name: String,
    val sourceName: String,
    val template: TypeTemplate,
    val hasConstructorDefault: Boolean,
    val overrides: List<FieldOwner>,
)

data class KspTypeDiagnostic(
    val path: List<String>,
    val message: String,
) {
    override fun toString(): String = "${path.joinToString(".")}: $message"
}

sealed interface KspTypeConversionResult {
    data class Success(
        val root: TypeUse,
        val definitions: List<TypeDefinition>,
        val ownedFields: Map<TypeDefinitionId, List<OwnedFieldDeclaration>>,
        val declarations: Map<TypeDefinitionId, KSClassDeclaration>,
    ) : KspTypeConversionResult

    data class Failure(
        val diagnostics: List<KspTypeDiagnostic>,
    ) : KspTypeConversionResult
}

class KspTypeGraphConverter(
    private val identityPolicy: KspTypeIdentityPolicy = KspTypeIdentityPolicy(::defaultIdentity),
    private val linkPolicy: KspLinkPolicy = KspLinkPolicy(::generatedEndpoint),
) {
    private val definitions = linkedMapOf<TypeDefinitionId, TypeDefinition>()
    private val ownedFields = linkedMapOf<TypeDefinitionId, List<OwnedFieldDeclaration>>()
    private val declarations = linkedMapOf<TypeDefinitionId, KSClassDeclaration>()
    private val diagnostics = mutableListOf<KspTypeDiagnostic>()
    private val visiting = mutableSetOf<TypeDefinitionId>()

    fun convert(type: KSType): KspTypeConversionResult {
        reset()
        val root = use(type, listOf(type.displayName))
        return if (root != null && diagnostics.isEmpty()) {
            KspTypeConversionResult.Success(root, definitions.values.toList(), ownedFields.toMap(), declarations.toMap())
        } else {
            KspTypeConversionResult.Failure(diagnostics.toList())
        }
    }

    fun convertDeclaration(declaration: KSClassDeclaration): KspTypeConversionResult {
        reset()
        val identity = identityPolicy.identity(declaration)
        buildDefinition(declaration, identity, listOf(declaration.simpleName.asString()))
        return if (diagnostics.isEmpty()) {
            KspTypeConversionResult.Success(
                root = TypeUse.Named(identity, emptyList()),
                definitions = definitions.values.toList(),
                ownedFields = ownedFields.toMap(),
                declarations = declarations.toMap(),
            )
        } else {
            KspTypeConversionResult.Failure(diagnostics.toList())
        }
    }

    private fun reset() {
        definitions.clear()
        ownedFields.clear()
        declarations.clear()
        diagnostics.clear()
        visiting.clear()
    }

    private fun use(
        type: KSType,
        path: List<String>,
    ): TypeUse? = template(type, null, path)?.complete(path)

    private fun TypeTemplate.complete(path: List<String>): TypeUse? =
        when (this) {
            is TypeTemplate.Parameter -> {
                failure(path, "A complete type use cannot contain a free parameter.")
            }

            is TypeTemplate.Named -> {
                val applied = arguments.mapIndexed { index, argument -> argument.complete(path + "argument $index") }
                if (applied.any { it == null }) null else TypeUse.Named(definition, applied.filterNotNull())
            }

            is TypeTemplate.Nullable -> {
                value.complete(path + "nullable")?.let(TypeUse::Nullable)
            }

            is TypeTemplate.Scalar -> {
                TypeUse.Scalar(kind)
            }
        }

    private fun template(
        type: KSType,
        owner: KSClassDeclaration?,
        path: List<String>,
        explicitParameterNullable: Boolean = false,
    ): TypeTemplate? {
        val value =
            when (val declaration = type.declaration) {
                is KSTypeParameter -> parameterTemplate(declaration, owner, path)
                is KSClassDeclaration -> classTemplate(type, declaration, owner, path)
                else -> failure(path, "Unsupported type declaration ${declaration.simpleName.asString()}.")
            }
        val explicitlyNullable = if (type.declaration is KSTypeParameter) explicitParameterNullable else type.nullability.name == "NULLABLE"
        return if (value != null && explicitlyNullable) TypeTemplate.Nullable(value) else value
    }

    private fun parameterTemplate(
        parameter: KSTypeParameter,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        if (owner == null) return failure(path, "A free type parameter has no declaration owner.")
        val index = owner.typeParameters.indexOf(parameter)
        if (index < 0) return failure(path, "A type parameter belongs to another declaration.")
        return TypeTemplate.Parameter(ParameterKey(identityPolicy.identity(owner), index))
    }

    private fun classTemplate(
        type: KSType,
        declaration: KSClassDeclaration,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        scalar(declaration.qualifiedName?.asString())?.let { return TypeTemplate.Scalar(it) }
        val qualified = declaration.qualifiedName?.asString()
        if (qualified == REFERENCE_TYPE) return referenceTemplate(type, owner, path)
        if (qualified in LIST_TYPES || qualified in SET_TYPES || qualified in MAP_TYPES) {
            val collectionName = requireNotNull(qualified)
            ensureCollectionDefinition(collectionName)
            val arguments =
                type.arguments.mapIndexed { index, argument ->
                    argument.type?.let { reference ->
                        template(reference.resolve(), owner, path + "argument $index", reference.explicitNullable)
                    }
                        ?: failure(path + "argument $index", "Star projections are not authorable.")
                }
            if (arguments.any { it == null }) return null
            return TypeTemplate.Named(collectionIdentity(collectionName), arguments.filterNotNull())
        }
        val identity = identityPolicy.identity(declaration)
        buildDefinition(declaration, identity, path)
        val arguments =
            type.arguments.mapIndexed { index, argument ->
                argument.type?.let { reference ->
                    template(reference.resolve(), owner, path + "argument $index", reference.explicitNullable)
                }
                    ?: failure(path + "argument $index", "Star projections are not authorable.")
            }
        if (arguments.any { it == null }) return null
        return TypeTemplate.Named(identity, arguments.filterNotNull())
    }

    private fun referenceTemplate(
        type: KSType,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        if (type.arguments.size != 2) return failure(path, "A resource reference requires an endpoint and target.")
        val endpointType =
            type.arguments[0].type?.resolve()
                ?: return failure(path + "endpoint", "A resource reference endpoint cannot use a star projection.")
        val endpointDeclaration =
            endpointType.declaration as? KSClassDeclaration
                ?: return failure(path + "endpoint", "A resource reference endpoint must be a generated declaration.")
        val endpoint =
            linkPolicy.endpoint(endpointDeclaration)
                ?: return failure(path + "endpoint", "The resource reference endpoint is not generated by a reference contract.")
        val targetType =
            type.arguments[1].type?.resolve()
                ?: return failure(path + "target", "A resource reference target cannot use a star projection.")
        val target = template(targetType, owner, path + "target", type.arguments[1].type?.explicitNullable == true) ?: return null
        val endpointName = endpointDeclaration.qualifiedName?.asString() ?: endpointDeclaration.simpleName.asString()
        val identity = TypeDefinitionId(TypeId.Qualified("relation", endpointName), 1)
        val targetParameter = ParameterKey(identity, 0)
        definitions.putIfAbsent(
            identity,
            TypeDefinition(
                identity,
                parameters = listOf(TypeParameter(targetParameter, "Target")),
                representation = RepresentationTemplate.Link(endpoint, TypeTemplate.Parameter(targetParameter)),
            ),
        )
        ownedFields.putIfAbsent(identity, emptyList())
        return TypeTemplate.Named(identity, listOf(target))
    }

    private fun buildDefinition(
        declaration: KSClassDeclaration,
        identity: TypeDefinitionId,
        path: List<String>,
    ) {
        if (identity in definitions || !visiting.add(identity)) return
        declarations[identity] = declaration
        val parameters =
            declaration.typeParameters.mapIndexed { index, parameter ->
                TypeParameter(
                    key = ParameterKey(identity, index),
                    name = parameter.name.asString(),
                    bounds =
                        parameter.bounds
                            .mapNotNull { reference ->
                                val bound = reference.resolve()
                                if (bound.declaration.qualifiedName?.asString() == "kotlin.Any") {
                                    null
                                } else {
                                    template(bound, declaration, path + parameter.name.asString())
                                }
                            }.toList(),
                )
            }
        val parents =
            declaration.superTypes
                .mapNotNull { reference ->
                    val parent = reference.resolve()
                    val qualified = parent.declaration.qualifiedName?.asString()
                    if (qualified == "kotlin.Any" || qualified == RESOURCE_MARKER) return@mapNotNull null
                    template(parent, declaration, path + "parent") as? TypeTemplate.Named
                }.toList()
        val fields = ownedFields(declaration, identity, path)
        ownedFields[identity] = fields
        val representation =
            when {
                declaration.hasAnnotation(TYPEWRITER_STRING_ANNOTATION) -> {
                    RepresentationTemplate.Scalar(ScalarKind.Text)
                }

                declaration.valueClassScalarKind() != null -> {
                    RepresentationTemplate.Scalar(requireNotNull(declaration.valueClassScalarKind()))
                }

                declaration.classKind == ClassKind.ENUM_CLASS -> {
                    RepresentationTemplate.Enumeration(
                        declaration.declarations
                            .filterIsInstance<KSClassDeclaration>()
                            .filter { it.classKind == ClassKind.ENUM_ENTRY }
                            .map { EnumVariant(it.serialName ?: it.simpleName.asString()) }
                            .toList(),
                    )
                }

                declaration.classKind == ClassKind.OBJECT && fields.isEmpty() -> {
                    RepresentationTemplate.Scalar(ScalarKind.Unit)
                }

                else -> {
                    RepresentationTemplate.Record(
                        fields =
                            fields.map { field ->
                                FieldDeclaration(
                                    owner = FieldOwner(field.owner, field.name),
                                    type = field.template,
                                    overrides = field.overrides,
                                    hasConstructorDefault = field.hasConstructorDefault,
                                )
                            },
                        abstract = declaration.classKind == ClassKind.INTERFACE || Modifier.ABSTRACT in declaration.modifiers,
                    )
                }
            }
        definitions[identity] = TypeDefinition(identity, parameters, representation, parents)
        visiting.remove(identity)
    }

    private fun KSClassDeclaration.valueClassScalarKind(): ScalarKind? {
        if (Modifier.VALUE !in modifiers && !hasAnnotation(JVM_INLINE_ANNOTATION)) return null
        val parameter = primaryConstructor?.parameters?.singleOrNull() ?: return null
        return scalar(
            parameter.type
                .resolve()
                .declaration.qualifiedName
                ?.asString(),
        )
    }

    private fun ensureCollectionDefinition(qualified: String) {
        val identity = collectionIdentity(qualified)
        if (identity in definitions) return
        val parameterCount = if (qualified in MAP_TYPES) 2 else 1
        val parameters =
            (0 until parameterCount).map { index ->
                TypeParameter(ParameterKey(identity, index), if (index == 0) "T" else "V")
            }
        val parameter = { index: Int -> TypeTemplate.Parameter(parameters[index].key) }
        val representation =
            when {
                qualified in LIST_TYPES -> RepresentationTemplate.Sequence(parameter(0), com.typewritermc.types.CollectionKind.List)
                qualified in SET_TYPES -> RepresentationTemplate.Sequence(parameter(0), com.typewritermc.types.CollectionKind.Set)
                else -> RepresentationTemplate.Mapping(parameter(0), parameter(1))
            }
        definitions[identity] = TypeDefinition(identity, parameters, representation)
        ownedFields[identity] = emptyList()
    }

    private fun ownedFields(
        declaration: KSClassDeclaration,
        identity: TypeDefinitionId,
        path: List<String>,
    ): List<OwnedFieldDeclaration> {
        return declaration.declarations
            .filterIsInstance<KSPropertyDeclaration>()
            .filter(KSPropertyDeclaration::isStoredTypeProperty)
            .mapNotNull { property ->
                val name = property.serialName ?: property.simpleName.asString()
                val fieldType =
                    template(property.type.resolve(), declaration, path + name, property.type.explicitNullable) ?: return@mapNotNull null
                val overrides =
                    declaration
                        .getAllSuperTypes()
                        .mapNotNull { it.declaration as? KSClassDeclaration }
                        .filter { parent ->
                            parent.declarations
                                .filterIsInstance<KSPropertyDeclaration>()
                                .any { it.simpleName.asString() == property.simpleName.asString() }
                        }.map { parent -> FieldOwner(identityPolicy.identity(parent), name) }
                        .distinct()
                        .toList()
                OwnedFieldDeclaration(
                    owner = identity,
                    name = name,
                    sourceName = property.simpleName.asString(),
                    template = fieldType,
                    hasConstructorDefault = property.hasConstructorDefault,
                    overrides = overrides,
                )
            }.toList()
    }

    private fun failure(
        path: List<String>,
        message: String,
    ): Nothing? {
        diagnostics += KspTypeDiagnostic(path, message)
        return null
    }
}

private fun defaultIdentity(declaration: KSClassDeclaration): TypeDefinitionId {
    val annotation = declaration.annotation(TYPEWRITER_TYPE_ANNOTATION)
    val id = annotation?.argument("id") as? String
    val revision = annotation?.argument("revision") as? Int ?: 1
    return if (id != null) {
        TypeDefinitionId(TypeId.Declared(DeclaredTypeId.parse(id)), revision)
    } else {
        val qualified = declaration.qualifiedName?.asString() ?: declaration.simpleName.asString()
        TypeDefinitionId(TypeId.Qualified("kotlin", qualified), 1)
    }
}

private fun generatedEndpoint(declaration: KSClassDeclaration): EndpointId? {
    val annotation = declaration.annotation(GENERATED_ENDPOINT_ANNOTATION) ?: return null
    val relation = annotation.argument("relation") as? String ?: return null
    val slot =
        annotation
            .argument("slot")
            ?.toString()
            ?.substringAfterLast('.')
            ?.lowercase() ?: return null
    return EndpointId("$relation:$slot")
}

private fun scalar(qualified: String?): ScalarKind? =
    when (qualified) {
        "kotlin.Unit" -> ScalarKind.Unit
        "kotlin.Boolean" -> ScalarKind.Boolean
        "kotlin.String", "kotlin.Char" -> ScalarKind.Text
        "kotlin.ByteArray" -> ScalarKind.Bytes
        "kotlin.Byte" -> ScalarKind.Integer(IntegerWidth.SIGNED_8)
        "kotlin.Short" -> ScalarKind.Integer(IntegerWidth.SIGNED_16)
        "kotlin.Int" -> ScalarKind.Integer(IntegerWidth.SIGNED_32)
        "kotlin.Long", "java.math.BigInteger" -> ScalarKind.Integer(IntegerWidth.SIGNED_64)
        "kotlin.UByte" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_8)
        "kotlin.UShort" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_16)
        "kotlin.UInt" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_32)
        "kotlin.ULong" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_64)
        "kotlin.Float" -> ScalarKind.Float(FloatWidth.FLOAT_32)
        "kotlin.Double" -> ScalarKind.Float(FloatWidth.FLOAT_64)
        "java.math.BigDecimal" -> ScalarKind.Decimal
        "kotlin.time.Instant", "java.time.Instant" -> ScalarKind.Timestamp
        "kotlin.time.Duration", "java.time.Duration" -> ScalarKind.Duration
        else -> null
    }

private fun collectionIdentity(qualified: String): TypeDefinitionId =
    TypeDefinitionId(
        TypeId.Qualified(
            "typewriter",
            when (qualified) {
                in LIST_TYPES -> "List"
                in SET_TYPES -> "Set"
                else -> "Map"
            },
        ),
        1,
    )

private val KSPropertyDeclaration.hasConstructorDefault: Boolean
    get() {
        val owner = parentDeclaration as? KSClassDeclaration ?: return false
        val name = simpleName.asString()
        return owner.primaryConstructor
            ?.parameters
            ?.firstOrNull { it.name?.asString() == name }
            ?.hasDefault == true
    }

private val KSType.displayName: String
    get() = declaration.qualifiedName?.asString() ?: declaration.simpleName.asString()

private val com.google.devtools.ksp.symbol.KSTypeReference.explicitNullable: Boolean
    get() = element?.toString()?.trim()?.endsWith("?") == true

private val KSDeclaration.serialName: String?
    get() = annotation(SERIAL_NAME_ANNOTATION)?.argument("value") as? String

private fun KSDeclaration.hasAnnotation(qualifiedName: String): Boolean = annotation(qualifiedName) != null

private fun KSDeclaration.annotation(qualifiedName: String): KSAnnotation? =
    annotations.firstOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun KSAnnotation.argument(name: String): Any? = arguments.firstOrNull { it.name?.asString() == name }?.value

private const val TYPEWRITER_TYPE_ANNOTATION = "com.typewritermc.types.TypewriterType"
private const val TYPEWRITER_STRING_ANNOTATION = "com.typewritermc.types.TypewriterString"
private const val JVM_INLINE_ANNOTATION = "kotlin.jvm.JvmInline"
private const val SERIAL_NAME_ANNOTATION = "kotlinx.serialization.SerialName"
private const val RESOURCE_MARKER = "com.typewritermc.types.Resource"
private const val REFERENCE_TYPE = "com.typewritermc.types.Ref"
private const val GENERATED_ENDPOINT_ANNOTATION = "com.typewritermc.types.TypewriterGeneratedEndpoint"

private val LIST_TYPES = setOf("kotlin.collections.List", "kotlin.collections.MutableList", "kotlin.collections.ArrayList")
private val SET_TYPES =
    setOf("kotlin.collections.Set", "kotlin.collections.MutableSet", "kotlin.collections.HashSet", "kotlin.collections.LinkedHashSet")
private val MAP_TYPES =
    setOf("kotlin.collections.Map", "kotlin.collections.MutableMap", "kotlin.collections.HashMap", "kotlin.collections.LinkedHashMap")
