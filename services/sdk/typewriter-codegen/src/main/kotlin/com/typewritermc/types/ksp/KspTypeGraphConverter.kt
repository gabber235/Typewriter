package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.FileLocation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSNode
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeArgument
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.KSTypeReference
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
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.Ref
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypewriterGeneratedEndpoint
import com.typewritermc.types.TypewriterString
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.functionTemplate
import com.typewritermc.types.functionUse
import com.typewritermc.types.member
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.nullable
import com.typewritermc.types.parse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import com.typewritermc.codegen.TypewriterApi as Api

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
    /** The declaration the author must change, when it is not the converted root. */
    val symbol: KSNode? = null,
) {
    override fun toString(): String = "${path.joinToString(".")}: $message"
}

/** The templates of one function signature's positions, with the type parameters the function owns. */
data class KspSignatureConversion(
    val typeParameters: List<TypeParameter>,
    val positions: List<TypeTemplate>,
    val definitions: List<TypeDefinition>,
    val declarations: Map<TypeDefinitionId, KSClassDeclaration>,
)

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

    /** The property whose type is being converted, where a diagnostic about that type belongs. */
    private var property: KSPropertyDeclaration? = null

    /** The function whose signature is being converted and the synthetic id that owns its type parameters. */
    private var signatureOwner: Pair<KSDeclaration, TypeDefinitionId>? = null

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
                root = identity.use(emptyList()),
                definitions = definitions.values.toList(),
                ownedFields = ownedFields.toMap(),
                declarations = declarations.toMap(),
            )
        } else {
            KspTypeConversionResult.Failure(diagnostics.toList())
        }
    }

    /**
     * The templates of [positions], types written in the signature of [function], whose own type parameters are keyed
     * by [owner]. A function is not a catalog definition, so [owner] is a synthetic id the caller chooses. Null after
     * the diagnostics are returned through [failures].
     */
    fun convertSignature(
        function: KSDeclaration,
        owner: TypeDefinitionId,
        positions: List<KSTypeReference>,
        failures: (List<KspTypeDiagnostic>) -> Unit,
    ): KspSignatureConversion? {
        reset()
        signatureOwner = function to owner
        try {
            val path = listOf(function.simpleName.asString())
            val parameters =
                function.typeParameters.mapIndexed { index, parameter ->
                    TypeParameter(
                        key = ParameterKey(owner = owner, index = index),
                        name = parameter.name.asString(),
                        bounds =
                            parameter.bounds
                                .map(KSTypeReference::resolve)
                                .filterNot { it.declaration.qualifiedName?.asString() == "kotlin.Any" }
                                .mapNotNull { template(it, null, path + parameter.name.asString()) }
                                .toList(),
                        derived = false,
                    )
                }
            val templates = positions.map { template(it.resolve(), null, path, it.explicitNullable) }
            if (diagnostics.isNotEmpty()) {
                failures(diagnostics.toList())
                return null
            }
            return KspSignatureConversion(parameters, templates.map(::checkNotNull), definitions.values.toList(), declarations.toMap())
        } finally {
            signatureOwner = null
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
            is TypeTemplate.ParameterWrapper -> {
                failure(path, "A complete type use cannot contain a free parameter.")
            }

            is TypeTemplate.NamedWrapper -> {
                val applied = value.arguments.mapIndexed { index, argument -> argument.complete(path + "argument $index") }
                if (applied.any { it == null }) null else value.definition.use(applied.filterNotNull())
            }

            is TypeTemplate.NullableWrapper -> {
                value.value.complete(path + "nullable")?.nullable()
            }

            is TypeTemplate.ScalarWrapper -> {
                value.use
            }

            is TypeTemplate.FunctionWrapper -> {
                val context = value.context.map { it.name to (it.type.complete(path + it.name) ?: return null) }
                val parameters = value.parameters.map { it.name to (it.type.complete(path + it.name) ?: return null) }
                val result = value.result.complete(path + "result") ?: return null
                functionUse(context = context, parameters = parameters, result = result)
            }

            else -> {
                unknownVariant(this)
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
        return if (value != null && explicitlyNullable) value.nullable() else value
    }

    private fun parameterTemplate(
        parameter: KSTypeParameter,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        signatureOwner?.let { (function, key) ->
            val index = function.typeParameters.indexOf(parameter)
            if (index >= 0) return ParameterKey(owner = key, index = index).template
        }
        if (owner == null) return failure(path, "A free type parameter has no declaration owner.")
        val index = owner.typeParameters.indexOf(parameter)
        if (index < 0) return failure(path, "A type parameter belongs to another declaration.")
        return ParameterKey(owner = identity(owner, path) ?: return null, index = index).template
    }

    private fun classTemplate(
        type: KSType,
        declaration: KSClassDeclaration,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        type.portableScalarKind()?.let { return it.template }
        if (type.isFunctionType) return kotlinFunctionTemplate(type, owner, path)
        if (declaration isType Ref::class.asClassName()) return referenceTemplate(type, owner, path)
        if (declaration isType Api.Var) return varTemplate(type, declaration, owner, path)
        val collection = declaration.collectionIdentity()
        if (collection != null) {
            ensureCollectionDefinition(collection)
            return collection.template(typeArguments(type, owner, path) ?: return null)
        }
        val identity = identity(declaration, path) ?: return null
        buildDefinition(declaration, identity, path)
        return identity.template(typeArguments(type, owner, path) ?: return null)
    }

    /** The templates of [type]'s arguments, or null when one of them is not authorable. */
    private fun typeArguments(
        type: KSType,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): List<TypeTemplate>? {
        val arguments =
            type.arguments.mapIndexed { index, argument ->
                argument.type?.let { reference ->
                    template(reference.resolve(), owner, path + "argument $index", reference.explicitNullable)
                }
                    ?: failure(path + "argument $index", "Star projections are not authorable.")
            }
        return arguments.takeIf { all -> all.none { it == null } }?.filterNotNull()
    }

    /**
     * A Kotlin function type lowers to a structural function type. Names are part of the type, so each parameter of a
     * function with two or more parameters must be named; a single unnamed parameter is named `it`.
     */
    private fun kotlinFunctionTemplate(
        type: KSType,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        val inputs = type.arguments.dropLast(1)
        val names = inputs.map { it.parameterName() }
        if (inputs.size >= 2 && names.any { it == null }) {
            return failure(path, "Name each parameter of a function type with two or more parameters.", property)
        }
        val parameters =
            inputs.mapIndexed { index, argument ->
                val name = names[index] ?: "it"
                val reference = argument.type ?: return failure(path + name, "Star projections are not authorable.")
                name to (template(reference.resolve(), owner, path + name, reference.explicitNullable) ?: return null)
            }
        val result = type.arguments.last().type ?: return failure(path + "result", "Star projections are not authorable.")
        return functionTemplate(
            parameters = parameters,
            result = template(result.resolve(), owner, path + "result", result.explicitNullable) ?: return null,
        )
    }

    /**
     * `Var<T, C>` lowers to the Var record applied to `T` and the function type its formulas have: no parameters, the
     * properties of the scope `C` as context, and `T` as result. Inside Var's own declaration `C` stays its parameter.
     */
    private fun varTemplate(
        type: KSType,
        declaration: KSClassDeclaration,
        owner: KSClassDeclaration?,
        path: List<String>,
    ): TypeTemplate? {
        val identity = identity(declaration, path) ?: return null
        buildDefinition(declaration, identity, path)
        val valueType = type.arguments[0].type ?: return failure(path + "value", "Star projections are not authorable.")
        val value = template(valueType.resolve(), owner, path + "value", valueType.explicitNullable) ?: return null
        val scopeType = type.arguments[1].type?.resolve() ?: return failure(path + "context", "Star projections are not authorable.")
        val formula =
            when (val scope = scopeType.declaration) {
                is KSTypeParameter -> {
                    parameterTemplate(scope, owner, path + "context") ?: return null
                }

                is KSClassDeclaration -> {
                    if (scope.classKind != ClassKind.INTERFACE) {
                        return failure(path + "context", "The context of a Var must be an interface.", property)
                    }
                    val context =
                        scope.getAllProperties().toList().map { slot ->
                            val name = slot.simpleName.asString()
                            name to
                                (template(slot.type.resolve(), owner, path + "context" + name, slot.type.explicitNullable) ?: return null)
                        }
                    functionTemplate(context = context, result = value)
                }

                else -> {
                    return failure(path + "context", "The context of a Var must be an interface.", property)
                }
            }
        return identity.template(listOf(value, formula))
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
        return identity.template(listOf(target))
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
                    key = ParameterKey(owner = identity, index = index),
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
                    derived = false,
                )
            }
        val parents =
            declaration.superTypes
                .mapNotNull { reference ->
                    val parent = reference.resolve()
                    val qualified = parent.declaration.qualifiedName?.asString()
                    if (qualified == "kotlin.Any" || (declaration.classKind == ClassKind.ENUM_CLASS && qualified == "kotlin.Enum")) {
                        return@mapNotNull null
                    }
                    template(parent, declaration, path + "parent")?.named
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
                    RepresentationTemplate.createScalar(kind = ScalarKind.TEXT)
                }

                declaration.valueClassScalarKind() != null -> {
                    RepresentationTemplate.createScalar(kind = requireNotNull(declaration.valueClassScalarKind()))
                }

                declaration.classKind == ClassKind.ENUM_CLASS -> {
                    val cases = declaration.enumEntries().map { entry -> unitCase(identity, entry) }
                    RepresentationTemplate.createRecord(fields = emptyList(), form = closedForm(cases))
                }

                declaration.classKind == ClassKind.OBJECT && fields.isEmpty() -> {
                    RepresentationTemplate.createScalar(kind = ScalarKind.UNIT)
                }

                else -> {
                    RepresentationTemplate.createRecord(
                        fields =
                            fields.map { field ->
                                FieldDeclaration(
                                    owner = FieldOwner(definition = field.owner, name = field.name),
                                    type = field.template,
                                    overrides = field.overrides,
                                    hasConstructorDefault = field.hasConstructorDefault,
                                )
                            },
                        form =
                            when {
                                Modifier.SEALED in declaration.modifiers -> {
                                    closedForm(
                                        declaration
                                            .casesInDeclarationOrder()
                                            .mapNotNull { case -> caseTemplate(declaration, case, path + case.simpleName.asString()) }
                                            .toList(),
                                    )
                                }

                                declaration.classKind == ClassKind.INTERFACE || Modifier.ABSTRACT in declaration.modifiers -> {
                                    RecordForm.OPEN
                                }

                                else -> {
                                    RecordForm.CONCRETE
                                }
                            },
                    )
                }
            }
        definitions[identity] = TypeDefinition(id = identity, parameters = parameters, representation = representation, parents = parents)
        visiting.remove(identity)
    }

    /** Declares the unit case [entry] of the enum [owner] and returns its template. */
    private fun unitCase(
        owner: TypeDefinitionId,
        entry: KSClassDeclaration,
    ): NamedTypeTemplate {
        val case = owner.member(entry.serialName ?: entry.simpleName.asString())
        definitions[case] =
            TypeDefinition(
                id = case,
                parameters = emptyList(),
                representation = RepresentationTemplate.createScalar(kind = ScalarKind.UNIT),
                parents = listOf(owner.namedTemplate()),
            )
        ownedFields[case] = emptyList()
        return case.namedTemplate()
    }

    /**
     * The template of the sealed subtype [case] in the parameters of [parent]. A generic case must pass each of its
     * own parameters straight to the parent, so the parent's arguments decide the case's arguments.
     */
    private fun caseTemplate(
        parent: KSClassDeclaration,
        case: KSClassDeclaration,
        path: List<String>,
    ): NamedTypeTemplate? {
        if (case.annotation<TypewriterType>() == null && case.parentDeclaration != parent) {
            return failure(path, "A sealed subtype must be nested in its parent or carry its own @TypewriterType.", case)
        }
        val identity = identity(case, path) ?: return null
        buildDefinition(case, identity, path)
        val parentIdentity = identity(parent, path) ?: return null
        val passed =
            case.superTypes
                .map { it.resolve() }
                .firstOrNull { it.declaration == parent }
                ?.arguments
                ?.map { it.type?.resolve()?.declaration }
                .orEmpty()
        val arguments =
            case.typeParameters.map { parameter ->
                val index = passed.indexOf(parameter)
                if (index < 0) {
                    return failure(path, "A generic sealed subtype must pass each of its type parameters to its parent.", case)
                }
                ParameterKey(owner = parentIdentity, index = index).template
            }
        return identity.namedTemplate(arguments)
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
                val outer = this.property
                this.property = property
                val fieldType =
                    try {
                        template(property.type.resolve(), declaration, path + name, property.type.explicitNullable)
                    } finally {
                        this.property = outer
                    } ?: return@mapNotNull null
                val overrides =
                    declaration
                        .getAllSuperTypes()
                        .mapNotNull { it.declaration as? KSClassDeclaration }
                        .filter { parent ->
                            parent.declarations
                                .filterIsInstance<KSPropertyDeclaration>()
                                .any { it.simpleName.asString() == property.simpleName.asString() }
                        }.mapNotNull { parent -> identity(parent, path + name)?.let { FieldOwner(definition = it, name = name) } }
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
        symbol: KSNode? = null,
    ): Nothing? {
        diagnostics += KspTypeDiagnostic(path, message, symbol)
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
            ?: sealedParent()?.let { parent -> return parent.typeDefinitionIdentity()?.member(serialName ?: simpleName.asString()) }
            ?: return TypeDefinitionId.qualified("kotlin", qualifiedName?.asString() ?: simpleName.asString())
    return type.identity()
}

/** The sealed declaration this one is nested in and extends, which names it as one of its cases. */
private fun KSClassDeclaration.sealedParent(): KSClassDeclaration? =
    (parentDeclaration as? KSClassDeclaration)?.takeIf { parent ->
        Modifier.SEALED in parent.modifiers && superTypes.any { it.resolve().declaration == parent }
    }

/**
 * The sealed subtypes of this declaration in an order that depends on the source alone, never on how KSP lists them:
 * nested ones in source order, then the others in this file in source order, then those of other files by package,
 * file name and line. The order is part of the catalog shape, and an enum's first case is its default.
 */
private fun KSClassDeclaration.casesInDeclarationOrder(): Sequence<KSClassDeclaration> {
    val nested = declarations.filterIsInstance<KSClassDeclaration>().toList()
    return getSealedSubclasses().sortedWith(
        compareBy(
            { case -> nested.indexOf(case).takeIf { it >= 0 } ?: Int.MAX_VALUE },
            { case -> case.containingFile != containingFile },
            { case -> case.packageName.asString() },
            { case -> case.containingFile?.fileName.orEmpty() },
            { case -> (case.location as? FileLocation)?.lineNumber ?: Int.MAX_VALUE },
            { case -> case.qualifiedName?.asString().orEmpty() },
        ),
    )
}

/** The entries of this enum class in declaration order. */
private fun KSClassDeclaration.enumEntries(): List<KSClassDeclaration> =
    declarations.filterIsInstance<KSClassDeclaration>().filter { it.classKind == ClassKind.ENUM_ENTRY }.toList()

/** The name a function type gives this argument, as `(level: Int) -> Int` does through `@ParameterName`. */
private fun KSTypeArgument.parameterName(): String? =
    (annotations + type?.annotations.orEmpty())
        .firstOrNull { it.shortName.asString() == "ParameterName" }
        ?.arguments
        ?.firstOrNull()
        ?.value as? String

private fun closedForm(cases: List<NamedTypeTemplate>): RecordForm = RecordForm.createClosed(cases = cases)

private fun TypewriterType.identity(): TypeDefinitionId? {
    val declared = runCatching { DeclaredTypeId.parse(id) }.getOrNull() ?: return null
    return TypeDefinitionId(typeId = TypeId.DeclaredWrapper(declared), revision = revision)
}

private fun generatedEndpoint(declaration: KSClassDeclaration): EndpointId? {
    val annotation = declaration.rawAnnotation(TypewriterGeneratedEndpoint::class) ?: return null
    val relation = annotation.argument("relation") as? String ?: return null
    val slot = annotation.enumArgumentOrNull<EndpointSlot>("slot") ?: return null
    return EndpointId(value = "$relation:${slot.name.lowercase()}")
}

private fun KSClassDeclaration.collectionIdentity(): TypeDefinitionId? =
    when {
        this isOneOf KnownTypes.lists -> StandardTypes.list
        this isOneOf KnownTypes.sets -> StandardTypes.set
        this isOneOf KnownTypes.maps -> StandardTypes.map
        this isType KnownTypes.intRange -> StandardTypes.intRange
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

private val KSTypeReference.explicitNullable: Boolean
    get() = resolve().isMarkedNullable
