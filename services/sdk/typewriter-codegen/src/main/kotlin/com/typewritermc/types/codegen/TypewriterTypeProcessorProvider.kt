package com.typewritermc.types.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.symbol.Variance
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.TypeVariableName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.TypeParameterResolver
import com.squareup.kotlinpoet.ksp.toTypeName
import com.squareup.kotlinpoet.ksp.toTypeParameterResolver
import com.typewritermc.capability.codegen.CapabilityProviderProcessor
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.KnownTypes
import com.typewritermc.codegen.TypeParameterBindings
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.argument
import com.typewritermc.codegen.compiledBounds
import com.typewritermc.codegen.enumArgumentOrNull
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.implements
import com.typewritermc.codegen.isOneOf
import com.typewritermc.codegen.isType
import com.typewritermc.codegen.portableScalarKind
import com.typewritermc.codegen.rawAnnotation
import com.typewritermc.codegen.sentenceCase
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.codegen.RegistrarProviderProcessor
import com.typewritermc.presentation.codegen.CollectionProjectionProviderProcessor
import com.typewritermc.types.Color
import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.Icon
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.Resource
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterRelationFamily
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports
import com.typewritermc.types.codegen.emit.CheckEmitter
import com.typewritermc.types.codegen.emit.ConfigurationEmitter
import com.typewritermc.types.codegen.emit.DefinitionEmitter
import com.typewritermc.types.codegen.emit.DisplayEmitter
import com.typewritermc.types.codegen.emit.DraftEmitter
import com.typewritermc.types.codegen.emit.ExpressionsEmitter
import com.typewritermc.types.codegen.emit.FieldsEmitter
import com.typewritermc.types.codegen.emit.NativeBindingEmitter
import com.typewritermc.types.codegen.emit.OperationsEmitter
import com.typewritermc.types.codegen.emit.PresentationEmitter
import com.typewritermc.types.codegen.emit.SdkEndpoint
import com.typewritermc.types.codegen.emit.SdkRelation
import com.typewritermc.types.codegen.emit.endpointBindingsFile
import com.typewritermc.types.codegen.emit.file
import com.typewritermc.types.codegen.emit.supportsNativeBinding
import com.typewritermc.types.ksp.EndpointUsageValidator
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.KspTypeGraphConverter
import com.typewritermc.types.ksp.OwnedFieldDeclaration
import com.typewritermc.types.ksp.typeDefinitionIdentity
import com.typewritermc.types.substitute
import com.typewritermc.types.toTemplate

class TypewriterTypeProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterTypeProcessor(environment.codeGenerator, environment.logger, environment.options)
}

/** Emission order is the order of declarations in each generated SDK file. */
internal val SDK_EMITTERS: List<SdkEmitter> =
    listOf(
        FieldsEmitter,
        ExpressionsEmitter,
        ConfigurationEmitter,
        OperationsEmitter,
        PresentationEmitter,
        DisplayEmitter,
        CheckEmitter,
        DraftEmitter,
        DefinitionEmitter,
        NativeBindingEmitter,
    )

/**
 * Collects contributions across KSP rounds and publishes one provider index when processing finishes.
 * Unresolved source graphs are deferred so contracts generated in earlier rounds can become inputs.
 * Emission sets belong to this compilation and prevent duplicate files across those rounds.
 *
 * Source declarations own their SDK output. Dependency declarations are claimed only when explicitly
 * imported or when the artifact opts into claiming its dependency closure. Generated adapters retain
 * authored callbacks; catalog assembly and runtime binding remain the consumers' responsibility.
 */
private class TypewriterTypeProcessor(
    codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val options: Map<String, String>,
) : SymbolProcessor {
    private val output = GeneratedOutput(codeGenerator, logger, options[SOURCE_PART_OPTION].orEmpty())
    private val owners = DefinitionOwners(logger, ::isEmittedHere)
    private val generatedTypes = mutableSetOf<String>()
    private val processedTypeRoots = mutableSetOf<String>()
    private val generatedRelations = mutableSetOf<String>()
    private val generatedEndpointBindingRoots = mutableSetOf<String>()
    private val explicitlyImportedTypes = mutableSetOf<String>()
    private val registrarProviders = RegistrarProviderProcessor(output, logger)
    private val collectionProjectionProviders = CollectionProjectionProviderProcessor(output, logger)
    private val capabilityProviders = CapabilityProviderProcessor(output, owners, logger, options[SOURCE_PART_OPTION].orEmpty())
    private val readModels = ReadModelProcessor(codeGenerator, logger)
    private val claimDependencyClosure = options[CLAIM_DEPENDENCY_CLOSURE_OPTION]?.toBooleanStrictOrNull() == true
    private var optionsValidated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        readModels.process(resolver)
        if (!optionsValidated) {
            optionsValidated = true
            if (!validateOptions()) return emptyList()
        }
        return context(resolver) { processRound() }
    }

    context(resolver: Resolver)
    private fun processRound(): List<KSAnnotated> {
        val deferred = mutableListOf<KSAnnotated>()
        deferred += registrarProviders.process(resolver)
        deferred += collectionProjectionProviders.process(resolver)
        deferred += capabilityProviders.process(resolver)
        resolver
            .getSymbolsWithAnnotation(TypewriterTypeImports::class)
            .filterIsInstance<KSClassDeclaration>()
            .forEach { carrier ->
                if (!carrier.validate()) {
                    deferred += carrier
                    return@forEach
                }
                val imported = carrier.rawAnnotation(TypewriterTypeImports::class)?.argument("types") as? List<*> ?: emptyList<Any>()
                imported
                    .filterIsInstance<KSType>()
                    .mapNotNull { type -> type.declaration as? KSClassDeclaration }
                    .forEach { declaration ->
                        declaration.qualifiedName?.asString()?.let(explicitlyImportedTypes::add)
                        if (declaration.isTypeGraphReady()) generateType(declaration) else deferred += carrier
                    }
            }
        resolver
            .getSymbolsWithAnnotation(ReferenceContract::class)
            .filterIsInstance<KSClassDeclaration>()
            .forEach { relation -> if (relation.validate()) generateRelation(relation) else deferred += relation }
        val directlyAnnotated = resolver.getSymbolsWithAnnotation(TypewriterType::class).filterIsInstance<KSClassDeclaration>().toList()
        val nestedAnnotated =
            directlyAnnotated
                .asSequence()
                .flatMap { declaration -> classes(declaration.declarations) + declaration.getSealedSubclasses() }
                .filter { declaration -> declaration.rawAnnotation(TypewriterType::class) != null }
        val declarations =
            (directlyAnnotated.asSequence() + nestedAnnotated)
                .distinctBy { it.qualifiedName?.asString() }
                .toList()
        declarations.filterNot { it.isTypeGraphReady() }.forEach(deferred::add)
        declarations
            .filter { it.isTypeGraphReady() }
            .sortedBy { it.qualifiedName?.asString() }
            .forEach { generateType(it) }
        resolver.getAllFiles().forEach { file ->
            classes(file.declarations).filter { it.classKind == ClassKind.OBJECT }.forEach { declaration ->
                val unresolved = declaration.superTypes.any { it.resolve().isError }
                if (unresolved) {
                    if (declaration.origin.name == "KOTLIN") deferred += declaration
                    return@forEach
                }
                generateAdapters(declaration)
            }
        }
        return deferred.distinct()
    }

    override fun finish() {
        output.finish()
    }

    /** Whether this compilation emits the SDK of [declaration]: its own sources and the dependencies it claims. */
    private fun isEmittedHere(declaration: KSClassDeclaration): Boolean =
        declaration.origin.name == "KOTLIN" ||
            claimDependencyClosure ||
            declaration.qualifiedName?.asString() in explicitlyImportedTypes

    context(resolver: Resolver)
    private fun generateRelation(declaration: KSClassDeclaration) {
        val qualified = declaration.qualifiedName?.asString() ?: return
        if (!generatedRelations.add(qualified)) return
        val id = declaration.annotation<ReferenceContract>()?.id
        if (id.isNullOrBlank()) {
            logger.error("Reference contracts require a stable id.", declaration)
            return
        }
        val name = ClassName(declaration.packageName.asString(), declaration.simpleName.asString().removeSuffix("Contract"))
        val endpointDeclarations = linkedMapOf<TypeDefinitionId, KSClassDeclaration>()
        val sources =
            declaration.declarations
                .filterIsInstance<KSClassDeclaration>()
                .mapNotNull { endpoint -> endpoint.relationEndpoint(endpointDeclarations) }
                .toList()
        if (sources.size != 2) {
            logger.error("Reference contracts require exactly two One or Many endpoint declarations.", declaration)
            return
        }
        val families =
            (sequenceOf(declaration) + declaration.getAllSuperTypes().mapNotNull { it.declaration as? KSClassDeclaration })
                .mapNotNull { it.annotation<TypewriterRelationFamily>()?.id }
                .distinct()
                .sorted()
                .toList()
        val (first, second) = sources.mapIndexed { index, source -> source.copy(slot = EndpointSlot.entries[index]).toEndpoint() }
        val referenced = (first.resourceTemplate.referencedIds() + second.resourceTemplate.referencedIds()).toSet()
        val references = owners.references(endpointDeclarations, referenced, declaration) ?: return
        val relation = SdkRelation(name, id, first, second, families, references)
        output.provide(relation.file(), name, GeneratedProviderKind.Relation, declaration)
        relation.endpoints.forEach { endpoint -> output.index(relation.linkDefinitionClass(endpoint), GeneratedProviderKind.Type) }
    }

    /** The endpoint marker of a nested contract interface, or null after reporting why it is not an endpoint. */
    private fun KSClassDeclaration.relationEndpoint(
        declarations: MutableMap<TypeDefinitionId, KSClassDeclaration>,
    ): RelationEndpointSource? {
        val marker =
            superTypes.map { it.resolve() }.firstOrNull { type ->
                type.declaration isType One::class.asClassName() || type.declaration isType Many::class.asClassName()
            } ?: return null
        val resource =
            marker.arguments
                .singleOrNull()
                ?.type
                ?.resolve()
        val resourceDeclaration = resource?.declaration as? KSClassDeclaration
        if (resourceDeclaration == null ||
            !(resourceDeclaration isType Resource::class.asClassName() || resourceDeclaration.implements(Resource::class))
        ) {
            logger.error("Relation endpoints must name a registered resource declaration.", this)
            return null
        }
        val resourceTemplate = resource.endpointTemplate(declarations)
        if (resourceTemplate == null) {
            logger.error("Relation endpoint resources require valid Typewriter type ids.", this)
            return null
        }
        return RelationEndpointSource(
            name = simpleName.asString(),
            slot = EndpointSlot.First,
            resourceType = resource,
            resourceTemplate = resourceTemplate as TypeTemplate.Named,
            cardinality = if (marker.declaration isType One::class.asClassName()) EndpointCardinality.One else EndpointCardinality.Many,
            onDelete =
                rawAnnotation(DeletionPolicy::class)?.enumArgumentOrNull<RelationDeletePolicy>("onDelete") ?: RelationDeletePolicy.CLEAR,
        )
    }

    context(resolver: Resolver)
    private fun generateType(declaration: KSClassDeclaration) {
        val qualified = declaration.qualifiedName?.asString() ?: return
        if (!processedTypeRoots.add(qualified)) return
        if (Modifier.PRIVATE in declaration.modifiers) {
            logger.error("Typewriter types must be visible qualified declarations.", declaration)
            return
        }
        if (!declaration.hasValidTypeIdentity()) return
        val conversion = KspTypeGraphConverter().convertDeclaration(declaration)
        if (conversion is KspTypeConversionResult.Failure) {
            conversion.diagnostics.forEach { logger.error(it.toString(), declaration) }
            return
        }
        conversion as KspTypeConversionResult.Success
        if (declaration.implements(Resource::class)) {
            val diagnostics = EndpointUsageValidator().validate(declaration)
            diagnostics.forEach { diagnostic -> logger.error(diagnostic.message, diagnostic.symbol) }
            if (diagnostics.isNotEmpty()) return
        }
        val references = owners.references(conversion, declaration) ?: return
        val definitions = conversion.definitions.associateBy(TypeDefinition::id)
        conversion.declarations.forEach { (definition, sourceDeclaration) ->
            if (!isEmittedHere(sourceDeclaration)) return@forEach
            emitSdk(sourceDeclaration, definitions.getValue(definition), conversion, references)
        }
        if (claimDependencyClosure) {
            conversion.declarations.values
                .asSequence()
                .flatMap(KSClassDeclaration::getSealedSubclasses)
                .filter { subclass -> subclass.rawAnnotation(TypewriterType::class) != null }
                .forEach { generateType(it) }
        }
        if (declaration.implements(Resource::class) && generatedEndpointBindingRoots.add(qualified)) {
            emitEndpointBindings(declaration, definitions, references)
        }
    }

    private fun emitSdk(
        declaration: KSClassDeclaration,
        typeDefinition: TypeDefinition,
        conversion: KspTypeConversionResult.Success,
        references: DefinitionReferences,
    ) {
        val qualified = declaration.qualifiedName?.asString() ?: return
        if (!generatedTypes.add(qualified)) return
        val accessors = declaration.effectiveAccessorFields(typeDefinition, conversion) ?: return
        val display = declaration.validatedDisplay() ?: return
        val searchKey = declaration.validatedSearchKey() ?: return
        val parameters = declaration.typeParameters.toTypeParameterResolver()
        val model =
            context(parameters) {
                val typeVariables = declaration.typeVariables()
                SdkDeclaration(
                    source = declaration,
                    definition = typeDefinition,
                    names = SdkNames.of(declaration),
                    typeVariables = typeVariables,
                    fields =
                        accessors.map { accessor ->
                            SdkField(
                                name = accessor.field.name,
                                property = accessor.field.sourceName,
                                template = accessor.field.template,
                                shape = classify(accessor.field.template, accessor.type),
                            )
                        },
                    ownedFields = conversion.ownedFields[typeDefinition.id].orEmpty(),
                    shape =
                        declaration.declarationShape(
                            template =
                                TypeTemplate.Named(
                                    typeDefinition.id,
                                    typeDefinition.parameters.map { TypeTemplate.Parameter(it.key) },
                                ),
                            native = SdkNames.of(declaration).source.parameterizedOrSelf(typeVariables),
                            arguments =
                                typeVariables.mapIndexed { index, variable ->
                                    FieldShape.Parameter(index, TypeTemplate.Parameter(ParameterKey(typeDefinition.id, index)), variable)
                                },
                        ),
                    references = references,
                    display = display,
                    searchKey = searchKey.value,
                )
            }
        val file = GeneratedFile.builder(model.names.definition.packageName, model.names.file)
        SDK_EMITTERS.forEach { emitter -> with(emitter) { file.emit(model) } }
        if (!output.write(file.build(), declaration)) return
        output.index(model.names.definition, GeneratedProviderKind.Type)
        if (declaration.supportsNativeBinding()) output.index(model.names.nativeBindingFactory, GeneratedProviderKind.NativeBinding)
    }

    /** The declaration's type variables without their variance and without `Any` bounds, as every emitted type uses them. */
    context(parameters: TypeParameterResolver)
    private fun KSClassDeclaration.typeVariables(): List<TypeVariableName> =
        typeParameters.map { parameter ->
            TypeVariableName(
                parameter.name.asString(),
                parameter
                    .compiledBounds()
                    .map { it.toTypeName(parameters) }
                    .toList(),
            )
        }

    /**
     * The complete display of this declaration: `@TypewriterDisplay` parts where given, otherwise the class name in
     * sentence case and the framework default icon and color. Null after reporting an invalid color.
     */
    private fun KSClassDeclaration.validatedDisplay(): TypeDisplay? {
        val display = annotation<TypewriterDisplay>()
        val color =
            display?.color?.takeIf(String::isNotEmpty)?.let { value ->
                runCatching { Color.parseRgb(value) }.getOrNull() ?: run {
                    logger.error("TypewriterDisplay color must use #RRGGBB syntax, found $value.", this)
                    return null
                }
            }
        return TypeDisplay(
            name = display?.name?.takeIf(String::isNotBlank) ?: simpleName.asString().sentenceCase(),
            description = display?.description.orEmpty(),
            icon = display?.icon?.takeIf(String::isNotBlank)?.let(Icon::parse) ?: TypeDisplay.DEFAULT_ICON,
            color = color ?: TypeDisplay.DEFAULT_COLOR,
        )
    }

    /**
     * The search scope keyword of a resource declaration, `@TypewriterDisplay(searchKey)` or the class name in lower
     * case; [Validated.value] is null for a type that is not a resource. Null after reporting an invalid key.
     */
    private fun KSClassDeclaration.validatedSearchKey(): Validated<String?>? {
        val declared = annotation<TypewriterDisplay>()?.searchKey.orEmpty()
        if (!implements(Resource::class)) {
            if (declared.isEmpty()) return Validated(null)
            logger.error("TypewriterDisplay searchKey requires a type that implements Resource.", this)
            return null
        }
        val key = declared.ifEmpty { simpleName.asString().lowercase() }
        if (!SEARCH_KEY.matches(key)) {
            logger.error(
                "TypewriterDisplay searchKey must be a lower case letter followed by lower case letters or digits, found $key.",
                this,
            )
            return null
        }
        return Validated(key)
    }

    private fun KSClassDeclaration.effectiveAccessorFields(
        root: TypeDefinition,
        conversion: KspTypeConversionResult.Success,
    ): List<EffectiveAccessorField>? {
        if (root.representation !is RepresentationTemplate.Record) return emptyList()
        val definitions = conversion.definitions.associateBy(TypeDefinition::id)
        var valid = true

        fun collect(
            template: TypeTemplate.Named,
            stack: Set<TypeDefinitionId>,
        ): List<OwnedFieldDeclaration> {
            if (template.definition in stack) return emptyList()
            val definition = definitions.getValue(template.definition)
            val substitutions =
                definition.parameters
                    .map(TypeParameter::key)
                    .zip(template.arguments)
                    .toMap()
            val inherited =
                definition.parents.flatMap { parent ->
                    collect(parent.substitute(substitutions) as TypeTemplate.Named, stack + template.definition)
                }
            val own =
                conversion.ownedFields[definition.id].orEmpty().map { field ->
                    field.copy(template = field.template.substitute(substitutions))
                }
            val ownByName = own.associateBy(OwnedFieldDeclaration::name)
            val inheritedByName = inherited.groupBy(OwnedFieldDeclaration::name)
            for ((name, candidates) in inheritedByName) {
                if (name !in ownByName && candidates.distinctBy { it.owner to it.template }.size > 1) {
                    logger.error("Ambiguous inherited authoring field $name requires an explicit override.", this)
                    valid = false
                }
            }
            return (inherited.map(OwnedFieldDeclaration::name) + own.map(OwnedFieldDeclaration::name)).distinct().map { name ->
                ownByName[name] ?: inheritedByName.getValue(name).first()
            }
        }
        val fields = collect(TypeTemplate.Named(root.id, root.parameters.map { TypeTemplate.Parameter(it.key) }), emptySet())
        for ((name, candidates) in fields.groupBy(OwnedFieldDeclaration::sourceName)) {
            if (candidates.size > 1) {
                logger.error(
                    "Authoring property $name maps to conflicting serialized fields; preserve its inherited serialized name.",
                    this,
                )
                valid = false
            }
        }
        if (!valid) return null
        val properties = getAllProperties().associateBy { it.simpleName.asString() }
        // Unlike a star projection, the declaration type preserves its own generic parameters.
        val containing = asType(emptyList())
        return fields
            .mapNotNull { field ->
                val property = properties[field.sourceName]
                if (property == null) {
                    logger.error("No Kotlin property resolves inherited authoring field ${field.name}.", this)
                    valid = false
                    return@mapNotNull null
                }
                val resolved = property.asMemberOf(containing)
                if (resolved.isError) {
                    logger.error("Cannot resolve authoring field ${field.name} in ${simpleName.asString()}.", property)
                    valid = false
                    return@mapNotNull null
                }
                EffectiveAccessorField(field, resolved)
            }.takeIf { valid }
    }

    private fun emitEndpointBindings(
        declaration: KSClassDeclaration,
        definitions: Map<TypeDefinitionId, TypeDefinition>,
        references: DefinitionReferences,
    ) {
        val identity = declaration.typeDefinitionIdentity() ?: return
        val root = definitions[identity] ?: return
        val rootTemplate = TypeTemplate.Named(root.id, root.parameters.map { TypeTemplate.Parameter(it.key) })
        val bindings = discoverEndpointBindings(rootTemplate, definitions)
        if (bindings.isEmpty()) return
        val names = SdkNames.of(declaration)
        output.provide(
            context(references) { endpointBindingsFile(names, bindings) },
            names.endpointBindings,
            GeneratedProviderKind.EndpointBindings,
            declaration,
        )
    }

    /**
     * Emits a provider for every generated contract [owner] implements, found through `@GeneratedContract`.
     * Runs for every object in every round: a contract reached through a supertype generated in a later round only
     * becomes visible then, and [GeneratedOutput] skips providers already written.
     */
    context(resolver: Resolver)
    private fun generateAdapters(owner: KSClassDeclaration) {
        owner.getAllSuperTypes().forEach { contract ->
            val declaration = contract.declaration as? KSClassDeclaration ?: return@forEach
            val marker = declaration.rawAnnotation(GeneratedContract::class) ?: return@forEach
            val kind = marker.enumArgumentOrNull<GeneratedContract.Kind>("kind") ?: return@forEach
            val target = (marker.argument("target") as? KSType)?.declaration as? KSClassDeclaration ?: return@forEach
            val adapter = ProviderAdapter(owner, target, kind)
            val file =
                when (kind) {
                    GeneratedContract.Kind.Configuration -> {
                        adapter.configuration()
                    }

                    GeneratedContract.Kind.Presentation -> {
                        adapter.presentation()
                    }

                    GeneratedContract.Kind.Check -> {
                        adapter.check()
                    }

                    GeneratedContract.Kind.Operations -> {
                        operationsAdapter(adapter, owner, contract, target)
                    }

                    GeneratedContract.Kind.Display -> {
                        adapter.display(
                            contract.arguments.map { requireNotNull(it.type).resolve().toTypeName() },
                        )
                    }
                } ?: return@forEach
            output.provide(file, adapter.name, kind.providerKind, owner)
        }
    }

    /** Validates an operations contract application and emits its provider, or reports why it cannot. */
    context(resolver: Resolver)
    private fun operationsAdapter(
        adapter: ProviderAdapter,
        owner: KSClassDeclaration,
        contract: KSType,
        resource: KSClassDeclaration,
    ): FileSpec? {
        val count = resource.typeParameters.size
        val nativeArguments = contract.arguments.take(count)
        if (contract.arguments.size != count * 2 ||
            contract.arguments.any { argument ->
                val type = argument.type?.resolve()
                type == null || type.isError || type.declaration is KSTypeParameter
            }
        ) {
            logger.error("Resource operations require closed native and projection arguments without stars.", owner)
            return null
        }
        val applied = resource.asType(nativeArguments)
        val conversion = KspTypeGraphConverter().convert(applied)
        if (conversion !is KspTypeConversionResult.Success || conversion.root !is TypeUse.Named) {
            logger.error("Resource operations require a supported closed resource application.", owner)
            return null
        }
        val application = conversion.root as TypeUse.Named
        val nativeTypes = nativeArguments.map { requireNotNull(it.type).resolve() }
        val shapes =
            context(emptyList<KSTypeParameter>().toTypeParameterResolver()) {
                application.arguments.zip(nativeTypes) { use, type -> classify(use.toTemplate(), type) }
            }
        val expected = shapes.map { it.draftType(emptyList()) }
        val actual = contract.arguments.drop(count).map { requireNotNull(it.type).resolve().toTypeName() }
        if (expected != actual) {
            logger.error(
                "Resource operation projection arguments must match their native arguments: expected ${expected.joinToString()}.",
                owner,
            )
            return null
        }
        val references = owners.references(conversion, owner, application.referencedIds()) ?: return null
        return context(references) {
            val projections = context(TypeParameterBindings.from(emptyMap())) { shapes.map { it.draftProjection() } }
            adapter.operations(application, nativeTypes.map { it.toTypeName() } + expected, projections)
        }
    }

    private fun validateOptions(): Boolean {
        val missing = listOf(ARTIFACT_OPTION, SOURCE_PART_OPTION).filter { options[it].isNullOrBlank() }
        missing.forEach { logger.error("Missing KSP option $it.") }
        val sourcePart = options[SOURCE_PART_OPTION]
        if (sourcePart != null && sourcePart.isNotBlank() && !GeneratedProviderIndex.SOURCE_PART.matches(sourcePart)) {
            logger.error("KSP option $SOURCE_PART_OPTION must be a letter followed by letters, digits or underscores.")
            return false
        }
        return missing.isEmpty()
    }

    /** Reports a malformed `@TypewriterType` id at this declaration instead of failing the KSP run. */
    private fun KSClassDeclaration.hasValidTypeIdentity(): Boolean {
        if (typeDefinitionIdentity() != null) return true
        logger.error("Typewriter type ids must be UUIDs.", this)
        return false
    }
}

/** A validation result whose [value] may itself be absent. */
private class Validated<T>(
    val value: T,
)

private data class EffectiveAccessorField(
    val field: OwnedFieldDeclaration,
    val type: KSType,
)

private data class RelationEndpointSource(
    val name: String,
    val slot: EndpointSlot,
    val resourceType: KSType,
    val resourceTemplate: TypeTemplate.Named,
    val cardinality: EndpointCardinality,
    val onDelete: RelationDeletePolicy,
) {
    fun toEndpoint(): SdkEndpoint = SdkEndpoint(name, slot, resourceType.toTypeName(), resourceTemplate, cardinality, onDelete)
}

private fun discoverEndpointBindings(
    root: TypeTemplate.Named,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): List<EndpointBindingTemplate> {
    val bindings = mutableListOf<EndpointBindingTemplate>()

    fun visit(
        template: TypeTemplate,
        path: List<FieldPatternSegment>,
        containsCollection: Boolean,
        valueOwner: TypeDefinitionId,
        stack: Set<Pair<TypeDefinitionId, Boolean>>,
    ) {
        when (template) {
            is TypeTemplate.Nullable -> {
                visit(template.value, path, containsCollection, valueOwner, stack)
            }

            is TypeTemplate.Parameter, is TypeTemplate.Scalar -> {}

            is TypeTemplate.Named -> {
                val definition = definitions[template.definition] ?: return
                val substitutions =
                    definition.parameters
                        .map(TypeParameter::key)
                        .zip(template.arguments)
                        .toMap()
                when (val representation = definition.representation) {
                    is RepresentationTemplate.Link -> {
                        bindings +=
                            EndpointBindingTemplate(
                                endpoint = representation.endpoint,
                                containingResource = root,
                                valueOwner = valueOwner,
                                relativePath = RelativeFieldPattern(path),
                                target = representation.target.substitute(substitutions),
                                containsCollection = containsCollection,
                            )
                    }

                    is RepresentationTemplate.Record -> {
                        val key = template.definition to containsCollection
                        if (key in stack) return
                        val nestedStack = stack + key
                        representation.fields.forEach { field ->
                            visit(
                                field.type.substitute(substitutions),
                                path + FieldPatternSegment.Field(field.owner.name),
                                containsCollection,
                                field.owner.definition,
                                nestedStack,
                            )
                        }
                    }

                    is RepresentationTemplate.Sequence -> {
                        visit(representation.item.substitute(substitutions), path + FieldPatternSegment.Items, true, valueOwner, stack)
                    }

                    is RepresentationTemplate.Mapping -> {
                        visit(representation.key.substitute(substitutions), path + FieldPatternSegment.Keys, true, valueOwner, stack)
                        visit(representation.value.substitute(substitutions), path + FieldPatternSegment.Values, true, valueOwner, stack)
                    }

                    is RepresentationTemplate.Enumeration, is RepresentationTemplate.Scalar -> {}
                }
            }
        }
    }

    visit(root, emptyList(), false, root.definition, emptySet())
    return bindings.distinct()
}

private fun classes(declarations: Sequence<KSDeclaration>): Sequence<KSClassDeclaration> =
    declarations.filterIsInstance<KSClassDeclaration>().flatMap { sequenceOf(it) + classes(it.declarations) }

/**
 * The portable template of a relation endpoint resource. Records each named declaration in [declarations], so the
 * relation can reference the generated definition that owns its id. Null when a declaration has a malformed type id.
 */
private fun KSType.endpointTemplate(declarations: MutableMap<TypeDefinitionId, KSClassDeclaration>): TypeTemplate? {
    val parameter = declaration as? KSTypeParameter
    if (parameter != null) {
        val owner =
            parameter.parentDeclaration as? KSClassDeclaration
                ?: error("Relation endpoint parameters require a declaration owner.")
        val index = owner.typeParameters.indexOf(parameter)
        require(index >= 0) { "Relation endpoint parameters must belong to their declaration." }
        val identity = owner.typeDefinitionIdentity() ?: return null
        declarations[identity] = owner
        return TypeTemplate.Parameter(ParameterKey(identity, index)).withNullability(this)
    }
    val declaration =
        declaration as? KSClassDeclaration
            ?: error("Relation endpoint arguments must use class or parameter types.")
    portableScalarKind()?.let { scalar -> return TypeTemplate.Scalar(scalar).withNullability(this) }
    val identity =
        when {
            declaration isOneOf KnownTypes.lists -> StandardTypes.list
            declaration isOneOf KnownTypes.sets -> StandardTypes.set
            declaration isOneOf KnownTypes.maps -> StandardTypes.map
            else -> (declaration.typeDefinitionIdentity() ?: return null).also { declarations[it] = declaration }
        }
    val arguments =
        arguments.mapIndexed { index, argument ->
            val type = argument.type?.resolve() ?: return@mapIndexed TypeTemplate.Parameter(ParameterKey(identity, index))
            type.endpointTemplate(declarations) ?: return null
        }
    return TypeTemplate.Named(identity, arguments).withNullability(this)
}

private fun TypeTemplate.withNullability(type: KSType): TypeTemplate = if (type.isMarkedNullable) TypeTemplate.Nullable(this) else this

private fun KSClassDeclaration.isTypeGraphReady(): Boolean {
    val references =
        sequence {
            yieldAll(superTypes)
            typeParameters.forEach { parameter -> yieldAll(parameter.bounds) }
            primaryConstructor?.parameters?.forEach { parameter -> yield(parameter.type) }
            getAllProperties().forEach { property -> yield(property.type) }
        }
    return references.all { reference -> runCatching { reference.resolve().isResolvedTypeGraph() }.getOrDefault(false) }
}

/** Star projections count as resolved, so the converter reports them at their declaration instead of deferring forever. */
private fun KSType.isResolvedTypeGraph(): Boolean =
    !isError &&
        arguments.all { argument ->
            argument.variance == Variance.STAR || argument.type?.resolve()?.isResolvedTypeGraph() == true
        }

private val SEARCH_KEY = Regex("[a-z][a-z0-9]*")

private const val ARTIFACT_OPTION = "typewriter.artifactId"
private const val SOURCE_PART_OPTION = "typewriter.sourcePart"
private const val CLAIM_DEPENDENCY_CLOSURE_OPTION = "typewriter.claimDependencyClosure"
