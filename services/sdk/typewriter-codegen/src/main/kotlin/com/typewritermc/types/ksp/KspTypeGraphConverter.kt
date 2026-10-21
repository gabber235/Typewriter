package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.squareup.kotlinpoet.asClassName
import com.typewritermc.codegen.KnownTypes
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.argument
import com.typewritermc.codegen.enumArgumentOrNull
import com.typewritermc.codegen.isOneOf
import com.typewritermc.codegen.isType
import com.typewritermc.codegen.portableScalarKind
import com.typewritermc.codegen.rawAnnotation
import com.typewritermc.codegen.serialName
import com.typewritermc.codegen.valueClassScalarKind
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.EnumVariant
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.Ref
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.Resource
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.TypewriterGeneratedEndpoint
import com.typewritermc.types.TypewriterString
import com.typewritermc.types.TypewriterType

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

/**
 * Builds the portable declaration closure reachable from one Kotlin root without emitting source.
 * Each conversion resets its mutable traversal state. Recursive references use declaration identity
 * to stop expansion while retaining the reference in the resulting template graph.
 *
 * Declaration conversion preserves owned generic parameters in templates; applied conversion requires
 * a closed root. Successful conversion describes the graph but does not replace catalog validation of
 * bounds, inheritance, or representation compatibility.
 */
class KspTypeGraphConverter(
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
        val path = listOf(declaration.simpleName.asString())
        val identity = identity(declaration, path) ?: return KspTypeConversionResult.Failure(diagnostics.toList())
        buildDefinition(declaration, identity, path)
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
        return TypeTemplate.Parameter(ParameterKey(identity(owner, path) ?: return null, index))
    }

    private fun classTemplate(
        type: KSType,
        declaration: KSClassDeclaration,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        type.portableScalarKind()?.let { return TypeTemplate.Scalar(it) }
        if (declaration isType Ref::class.asClassName()) return referenceTemplate(type, owner, path)
        val collection = declaration.collectionIdentity()
        if (collection != null) {
            ensureCollectionDefinition(collection)
            val arguments =
                type.arguments.mapIndexed { index, argument ->
                    argument.type?.let { reference ->
                        template(reference.resolve(), owner, path + "argument $index", reference.explicitNullable)
                    }
                        ?: failure(path + "argument $index", "Star projections are not authorable.")
                }
            if (arguments.any { it == null }) return null
            return TypeTemplate.Named(collection, arguments.filterNotNull())
        }
        val identity = identity(declaration, path) ?: return null
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
        val identity = relationLinkId(endpointName)
        definitions.putIfAbsent(identity, relationLinkDefinition(endpointName, endpoint))
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
                    if (qualified == "kotlin.Any" || parent.declaration isType Resource::class.asClassName() ||
                        (declaration.classKind == ClassKind.ENUM_CLASS && qualified == "kotlin.Enum")
                    ) {
                        return@mapNotNull null
                    }
                    template(parent, declaration, path + "parent") as? TypeTemplate.Named
                }.toList()
        val fields =
            if ((declaration.annotation<TypewriterString>() != null) || declaration.valueClassScalarKind() != null) {
                emptyList()
            } else {
                ownedFields(declaration, identity, path)
            }
        ownedFields[identity] = fields
        val representation =
            when {
                (declaration.annotation<TypewriterString>() != null) -> {
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

    private fun ensureCollectionDefinition(identity: TypeDefinitionId) {
        if (identity in definitions) return
        StandardTypes.definitions.single { it.id == identity }.let { definitions[identity] = it }
        ownedFields[identity] = emptyList()
    }

    private fun identity(
        declaration: KSClassDeclaration,
        path: List<String>,
    ): TypeDefinitionId? = declaration.typeDefinitionIdentity() ?: failure(path, "Typewriter type ids must be UUIDs.")

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
                        }.mapNotNull { parent -> identity(parent, path + name)?.let { FieldOwner(it, name) } }
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

/**
 * The identity of a declaration: its `@TypewriterType` id when declared, otherwise its qualified Kotlin name.
 * Null when the declared id is not a UUID, so callers report it at the declaration instead of failing the KSP run.
 */
fun KSClassDeclaration.typeDefinitionIdentity(): TypeDefinitionId? {
    val type =
        annotation<TypewriterType>()
            ?: return TypeDefinitionId(TypeId.Qualified("kotlin", qualifiedName?.asString() ?: simpleName.asString()), 1)
    return type.identity()
}

private fun TypewriterType.identity(): TypeDefinitionId? {
    val declared = runCatching { DeclaredTypeId.parse(id) }.getOrNull() ?: return null
    return TypeDefinitionId(TypeId.Declared(declared), revision)
}

private fun generatedEndpoint(declaration: KSClassDeclaration): EndpointId? {
    val annotation = declaration.rawAnnotation(TypewriterGeneratedEndpoint::class) ?: return null
    val relation = annotation.argument("relation") as? String ?: return null
    val slot = annotation.enumArgumentOrNull<EndpointSlot>("slot") ?: return null
    return EndpointId("$relation:${slot.name.lowercase()}")
}

private fun KSClassDeclaration.collectionIdentity(): TypeDefinitionId? =
    when {
        this isOneOf KnownTypes.lists -> StandardTypes.list
        this isOneOf KnownTypes.sets -> StandardTypes.set
        this isOneOf KnownTypes.maps -> StandardTypes.map
        else -> null
    }

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
    get() = resolve().isMarkedNullable
