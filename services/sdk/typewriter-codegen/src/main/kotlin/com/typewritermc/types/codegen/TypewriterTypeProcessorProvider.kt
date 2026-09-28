package com.typewritermc.types.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.stringMapCode
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.PrototypeBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.elements.TypewriterContent
import com.typewritermc.types.CatalogAbstractTypePrototype
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.DataPath
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.GeneratedTypeGraph
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.Relation
import com.typewritermc.types.RelationCardinality
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationEndpointDefinition
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.SerializationConcreteTypePrototype
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototype
import com.typewritermc.types.TypePrototypeProvider
import com.typewritermc.types.TypewriterRelation
import com.typewritermc.types.TypewriterRelationFamily
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.KspTypeGraphConverter
import com.typewritermc.types.ksp.KspTypeIdentityPolicy
import com.typewritermc.types.ksp.serializedFieldNames
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.encodeToByteArray
import kotlin.io.encoding.Base64

/**
 * KSP entrypoint generating concrete type prototypes and portable schema contributions from [TypewriterType]
 * declarations. It converts each declared type into a graph, writes a generated prototype provider, and emits the
 * resource consumed by manifest discovery. [com.typewritermc.discovery.runtime.PrototypeRegistryLoader] later
 * resolves those providers in the deployment class loader; runtime code therefore does not scan source annotations.
 * Processing defers unresolved symbols, validates declaration shape and identity, and writes once per compilation.
 */
class TypewriterTypeProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterTypeProcessor(environment.codeGenerator, environment.logger, environment.options)
}

@OptIn(ExperimentalSerializationApi::class)
private class TypewriterTypeProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val options: Map<String, String>,
) : SymbolProcessor {
    private var generated = false
    private val generatedPrototypeReferences = mutableSetOf<ResolvedTypeRef>()

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterType::class).distinct().toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        if (!validateContextArguments()) return emptyList()

        val candidates = symbols.filterIsInstance<KSClassDeclaration>()
        val declarations = candidates.mapNotNull(::validateDeclaration).sortedBy { it.qualifiedName!!.asString() }
        if (declarations.size != candidates.size) return emptyList()
        val indexed = declarations.associateWith(KSClassDeclaration::typeIdentity)
        val duplicateIds = indexed.entries.groupBy { it.value.reference }.filterValues { it.size > 1 }
        duplicateIds.forEach { (reference, entries) ->
            entries.forEach { logger.error("Duplicate Typewriter type identity $reference.", it.key) }
        }
        if (duplicateIds.isNotEmpty()) return emptyList()

        val indexedByName =
            buildMap {
                resolver
                    .getSymbolsWithAnnotation(TypewriterContent::class)
                    .filterIsInstance<KSClassDeclaration>()
                    .forEach { declaration ->
                        declaration
                            .annotation<TypewriterContent>()
                            ?.declaredIdentity()
                            ?.let { put(declaration.qualifiedName!!.asString(), it) }
                    }
                indexed.forEach { (declaration, identity) -> put(declaration.qualifiedName!!.asString(), identity) }
            }
        val identityPolicy =
            KspTypeIdentityPolicy { declaration ->
                indexedByName[declaration.qualifiedName?.asString()]?.reference
                    ?: declaration.declaredTypeReference()
                    ?: declaration.qualifiedReference()
            }
        val displayNames = indexedByName.map { (name, identity) -> identity.reference to name.substringAfterLast('.') }.toMap()
        val generatedTypes = declarations.mapNotNull { generateType(it, indexed.getValue(it), identityPolicy, displayNames) }
        if (generatedTypes.size != declarations.size) return emptyList()

        val relations = discoverRelations(resolver, identityPolicy) ?: return emptyList()
        writeContribution(generatedTypes, relations)
        generated = true
        return emptyList()
    }

    private fun validateContextArguments(): Boolean {
        var valid = true
        if (options[ARTIFACT_ID_OPTION].isNullOrBlank()) {
            logger.error("Missing KSP option $ARTIFACT_ID_OPTION.")
            valid = false
        }
        if (options[SOURCE_PART_OPTION].isNullOrBlank()) {
            logger.error("Missing KSP option $SOURCE_PART_OPTION.")
            valid = false
        }
        return valid
    }

    private fun validateDeclaration(symbol: KSAnnotated): KSClassDeclaration? {
        val declaration = symbol as? KSClassDeclaration
        if (declaration == null || declaration.classKind !in setOf(ClassKind.CLASS, ClassKind.INTERFACE, ClassKind.OBJECT)) {
            logger.error("TypewriterType may only annotate classes, interfaces, and objects.", symbol)
            return null
        }
        if (Modifier.PRIVATE in declaration.modifiers || declaration.qualifiedName == null) {
            logger.error("Indexed Typewriter types must be visible qualified declarations.", declaration)
            return null
        }
        val declared = declaration.annotation<TypewriterType>()
        if (declared == null || runCatching { DeclaredTypeId.parse(declared.id) }.isFailure) {
            logger.error("Typewriter type ids must contain exactly 32 hexadecimal characters.", declaration)
            return null
        }
        if (declared.revision <= 0) {
            logger.error("Typewriter type revisions must be positive.", declaration)
            return null
        }
        return declaration
    }

    private fun generateType(
        declaration: KSClassDeclaration,
        identity: IndexedIdentity,
        identityPolicy: KspTypeIdentityPolicy,
        displayNames: Map<ResolvedTypeRef, String>,
    ): GeneratedType? {
        val conversion = KspTypeGraphConverter(identityPolicy).convert(declaration.asStarProjectedType())
        val graph =
            when (conversion) {
                is KspTypeConversionResult.Success -> {
                    conversion.graph.withDisplayNames(displayNames)
                }

                is KspTypeConversionResult.Failure -> {
                    conversion.diagnostics.forEach { logger.error(it.toString(), declaration) }
                    return null
                }
            }
        val root = graph.root as? TypeExpression.Named
        if (root?.reference != identity.reference) {
            logger.error("Indexed type graph root did not retain its declared identity.", declaration)
            return null
        }
        val prototypes =
            conversion.declarations.entries
                .filter { (reference, concreteDeclaration) ->
                    concreteDeclaration.declaredTypeReference() != null
                }.mapNotNull { (reference, concreteDeclaration) ->
                    if (!generatedPrototypeReferences.add(reference)) return@mapNotNull null
                    GeneratedPrototype(
                        concreteDeclaration,
                        reference,
                        generatePrototype(concreteDeclaration, graph, reference),
                    )
                }
        return GeneratedType(declaration, graph, prototypes)
    }

    private fun generatePrototype(
        declaration: KSClassDeclaration,
        graph: TypeGraph,
        reference: ResolvedTypeRef,
    ): ClassName {
        val sourceClass = declaration.toClassName()
        val objectName = "${declaration.simpleName.asString()}TypewriterPrototype"
        val providerName = "${objectName}Provider"
        val packageName = declaration.packageName.asString()
        val encodedGraph = Base64.encode(Cbor.Default.encodeToByteArray(graph))
        val definition = graph.definitions.single { it.id == reference }
        val prototype =
            if (definition.kind == NominalTypeKind.CONCRETE) {
                TypeSpec
                    .objectBuilder(objectName)
                    .superclass(SerializationConcreteTypePrototype::class.asClassName().parameterizedBy(sourceClass))
                    .addSuperclassConstructorParameter("%T::class", sourceClass)
                    .addSuperclassConstructorParameter("%L", reference.code())
                    .addSuperclassConstructorParameter("graph.definitions.single { it.id == %L }", reference.code())
                    .addSuperclassConstructorParameter("%T.serializer()", sourceClass)
                    .addSuperclassConstructorParameter("%L", declaration.serializedFieldNames().stringMapCode())
                    .build()
            } else {
                TypeSpec
                    .objectBuilder(objectName)
                    .superclass(CatalogAbstractTypePrototype::class.asClassName().parameterizedBy(sourceClass))
                    .addSuperclassConstructorParameter("%T::class", sourceClass)
                    .addSuperclassConstructorParameter("%L", reference.code())
                    .addSuperclassConstructorParameter("graph.definitions.single { it.id == %L }", reference.code())
                    .addSuperclassConstructorParameter("%L", declaration.serializedFieldNames().stringMapCode())
                    .build()
            }
        val provider =
            TypeSpec
                .classBuilder(providerName)
                .addSuperinterface(TypePrototypeProvider::class)
                .addFunction(
                    FunSpec
                        .builder("prototype")
                        .addModifiers(KModifier.OVERRIDE)
                        .returns(TypePrototype::class.asClassName().parameterizedBy(STAR))
                        .addStatement("return %L", objectName)
                        .build(),
                ).build()
        FileSpec
            .builder(packageName, objectName)
            .indent("    ")
            .addProperty(
                PropertySpec
                    .builder("graph", TypeGraph::class)
                    .addModifiers(KModifier.PRIVATE)
                    .initializer("%T.decode(%S)", GeneratedTypeGraph::class, encodedGraph)
                    .build(),
            ).addType(prototype)
            .addType(provider)
            .build()
            .writeTo(codeGenerator, aggregating = false, originatingKSFiles = listOfNotNull(declaration.containingFile))
        return ClassName(packageName, providerName)
    }

    private fun writeContribution(
        types: List<GeneratedType>,
        relations: List<RelationDefinition>,
    ) {
        val authoritativeDefinitions =
            types.associate { generated ->
                val root = (generated.graph.root as TypeExpression.Named).reference
                root to generated.graph.definitions.single { it.id == root }
            }
        val definitions = mergeDefinitions(types.flatMap { it.graph.definitions }, authoritativeDefinitions) ?: return
        val contribution =
            TypeDiscoveryContribution(
                definitions = definitions,
                prototypeBindings =
                    types.flatMap { generated ->
                        generated.prototypes.map { prototype ->
                            PrototypeBinding(
                                type = prototype.reference,
                                runtimeClass = prototype.declaration.qualifiedName!!.asString(),
                                prototypeProviderClass = prototype.providerClass.canonicalName,
                                domains = setOf(DiscoveryDomains.Realm, DiscoveryDomains.Execution),
                            )
                        }
                    },
                executableBindings = emptyList(),
                relations = relations,
            )
        val files = types.mapNotNull { it.declaration.containingFile }.toTypedArray()
        codeGenerator
            .createNewFileByPath(
                Dependencies(aggregating = true, *files),
                "META-INF/typewriter/contributions/types/declared.cbor",
                "",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(contribution)) }
    }

    private fun discoverRelations(
        resolver: Resolver,
        identityPolicy: KspTypeIdentityPolicy,
    ): List<RelationDefinition>? {
        var valid = true
        val definitions = mutableListOf<RelationDefinition>()
        resolver.getSymbolsWithAnnotation(TypewriterRelation::class).forEach { symbol ->
            val marker = symbol as? KSClassDeclaration ?: return@forEach
            val annotation = marker.annotation<TypewriterRelation>() ?: return@forEach
            val relationTypes = marker.relationTypes()
            val source = relationTypes?.first?.declaration as? KSClassDeclaration
            val target = relationTypes?.second?.declaration as? KSClassDeclaration
            if (source == null || target == null) {
                logger.error("Relation markers must resolve Relation<Source, Target>.", marker)
                valid = false
                return@forEach
            }
            val id = runCatching { RelationId(annotation.id) }.getOrElse {
                logger.error(it.message ?: "Invalid relation id.", marker)
                valid = false
                return@forEach
            }
            val sourceEndpoint = marker.endpointOn(source, target, RelationEndpointSide.SOURCE, identityPolicy)
            val targetEndpoint = marker.endpointOn(target, source, RelationEndpointSide.TARGET, identityPolicy)
            if (sourceEndpoint == null) {
                logger.error("Relation $id requires one source field.", marker)
                valid = false
                return@forEach
            }
            definitions += RelationDefinition(
                id = id,
                source = identityPolicy.identity(source),
                target = identityPolicy.identity(target),
                onSourceDelete = annotation.onSourceDelete,
                onTargetDelete = annotation.onTargetDelete,
                sourceEndpoint = sourceEndpoint,
                targetEndpoint = targetEndpoint,
                families =
                    (marker.getAllSuperTypes().map { it.declaration } + marker)
                        .filterIsInstance<KSClassDeclaration>()
                        .mapNotNull { it.annotation<TypewriterRelationFamily>()?.id }
                        .map(::RelationFamilyId)
                        .toSet(),
            )
        }
        val duplicates = definitions.groupBy(RelationDefinition::id).filterValues { it.size > 1 }
        duplicates.forEach { (id, _) -> logger.error("Relation id $id is declared more than once."); valid = false }
        return if (valid) definitions.sortedBy { it.id.value } else null
    }

    private fun KSClassDeclaration.endpointOn(
        owner: KSClassDeclaration,
        opposite: KSClassDeclaration,
        side: RelationEndpointSide,
        identityPolicy: KspTypeIdentityPolicy,
    ): RelationEndpointDefinition? {
        val markerName = qualifiedName?.asString()
        val properties = owner.getAllProperties().filter { property ->
            val type = property.type.resolve()
            type.declaration.qualifiedName?.asString() in setOf(TO_ONE_TYPE, TO_MANY_TYPE) &&
                type.arguments.getOrNull(0)?.type?.resolve()?.declaration?.qualifiedName?.asString() == markerName
        }.toList()
        if (properties.size > 1) {
            logger.error("One relation marker may bind only one field on each endpoint.", owner)
            return null
        }
        val property = properties.singleOrNull() ?: return null
        val type = property.type.resolve()
        val endpointTarget = type.arguments.getOrNull(1)?.type?.resolve()?.declaration as? KSClassDeclaration
        if (endpointTarget == null || identityPolicy.identity(endpointTarget) != identityPolicy.identity(opposite)) {
            logger.error("Relation endpoint target must match the marker declaration.", property)
            return null
        }
        return RelationEndpointDefinition(
            owner = identityPolicy.identity(owner),
            path = DataPath.field(owner.serializedFieldNames()[property.simpleName.asString()] ?: property.simpleName.asString()),
            side = side,
            cardinality = if (type.declaration.qualifiedName?.asString() == TO_MANY_TYPE)
                RelationCardinality.MANY else RelationCardinality.ONE,
        )
    }

    private fun KSClassDeclaration.relationTypes(): Pair<KSType, KSType>? {
        fun resolve(type: KSType, bindings: Map<KSTypeParameter, KSType>): KSType =
            (type.declaration as? KSTypeParameter)?.let(bindings::get) ?: type

        fun visit(
            declaration: KSClassDeclaration,
            bindings: Map<KSTypeParameter, KSType>,
            visited: Set<KSClassDeclaration>,
        ): Pair<KSType, KSType>? {
            if (declaration in visited) return null
            declaration.superTypes.forEach { reference ->
                val superType = reference.resolve()
                val superDeclaration = superType.declaration as? KSClassDeclaration ?: return@forEach
                val arguments = superType.arguments.mapNotNull { it.type?.resolve()?.let { type -> resolve(type, bindings) } }
                if (superDeclaration.qualifiedName?.asString() == Relation::class.qualifiedName) {
                    if (arguments.size == 2) return arguments[0] to arguments[1]
                    return@forEach
                }
                val nextBindings = superDeclaration.typeParameters.zip(arguments).toMap()
                visit(superDeclaration, nextBindings, visited + declaration)?.let { return it }
            }
            return null
        }

        return visit(this, emptyMap(), emptySet())
    }

    private fun mergeDefinitions(
        definitions: List<TypeDefinition>,
        authoritative: Map<ResolvedTypeRef, TypeDefinition>,
    ): List<TypeDefinition>? {
        val merged = linkedMapOf<ResolvedTypeRef, TypeDefinition>()
        definitions.sortedBy { it.id.toString() }.forEach { definition ->
            val selected = authoritative[definition.id] ?: definition
            val previous = merged.putIfAbsent(definition.id, selected)
            if (previous != null && previous != selected && definition.id !in authoritative) {
                logger.error("Conflicting generated type definition ${definition.id}.")
                return null
            }
        }
        return merged.values.toList()
    }
}

private data class IndexedIdentity(
    val reference: ResolvedTypeRef,
)

private data class GeneratedType(
    val declaration: KSClassDeclaration,
    val graph: TypeGraph,
    val prototypes: List<GeneratedPrototype>,
)

private data class GeneratedPrototype(
    val declaration: KSClassDeclaration,
    val reference: ResolvedTypeRef,
    val providerClass: ClassName,
)

private fun KSClassDeclaration.typeIdentity(): IndexedIdentity =
    requireNotNull(requireNotNull(annotation<TypewriterType>()).declaredIdentity())

private fun TypewriterType.declaredIdentity(): IndexedIdentity? {
    val id = runCatching { DeclaredTypeId.parse(id) }.getOrNull() ?: return null
    return IndexedIdentity(ResolvedTypeRef(TypeId.Declared(id), revision))
}

private fun KSClassDeclaration.declaredTypeReference(): ResolvedTypeRef? {
    val annotation = annotation<TypewriterType>() ?: return null
    return annotation.declaredIdentity()?.reference
}

private fun TypewriterContent.declaredIdentity(): IndexedIdentity? {
    val id = runCatching { DeclaredTypeId.parse(id) }.getOrNull() ?: return null
    return IndexedIdentity(ResolvedTypeRef(TypeId.Declared(id), revision))
}

private fun KSClassDeclaration.qualifiedReference(): ResolvedTypeRef {
    val packageName = packageName.asString()
    val name = qualifiedName!!.asString().removePrefix("$packageName.")
    return ResolvedTypeRef(TypeId.Qualified(packageName, name), revision = 1)
}

private fun TypeGraph.withDisplayNames(displayNames: Map<ResolvedTypeRef, String>): TypeGraph =
    copy(
        definitions =
            definitions.map { definition ->
                displayNames[definition.id]?.let { definition.copy(displayName = it) } ?: definition
            },
    )

private fun ResolvedTypeRef.code(): String {
    val typeId =
        when (val value = id) {
            is TypeId.Declared -> {
                "com.typewritermc.types.TypeId.Declared(" +
                    "com.typewritermc.types.DeclaredTypeId.parse(\"${value.id}\"))"
            }

            is TypeId.Qualified -> {
                "com.typewritermc.types.TypeId.Qualified(\"${value.namespace}\", \"${value.name}\")"
            }

            is TypeId.Builtin -> {
                error("Generated concrete prototypes cannot use built in identities.")
            }
        }
    return "com.typewritermc.types.ResolvedTypeRef($typeId, $revision)"
}

private const val ARTIFACT_ID_OPTION = "typewriter.artifactId"
private const val SOURCE_PART_OPTION = "typewriter.sourcePart"
private const val TO_ONE_TYPE = "com.typewritermc.types.ToOne"
private const val TO_MANY_TYPE = "com.typewritermc.types.ToMany"
