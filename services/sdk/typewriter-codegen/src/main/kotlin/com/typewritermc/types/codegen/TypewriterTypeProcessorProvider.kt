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
import com.typewritermc.elements.TypewriterElement
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
                    .getSymbolsWithAnnotation(TypewriterElement::class)
                    .filterIsInstance<KSClassDeclaration>()
                    .forEach { declaration ->
                        declaration
                            .annotation<TypewriterElement>()
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

        val relations = discoverRelations(declarations, identityPolicy) ?: return emptyList()
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
        declarations: List<KSClassDeclaration>,
        identityPolicy: KspTypeIdentityPolicy,
    ): List<RelationDefinition>? {
        data class Partial(
            val base: RelationDefinition,
            val source: RelationEndpointDefinition? = null,
            val target: RelationEndpointDefinition? = null,
        )

        val partials = linkedMapOf<RelationId, Partial>()
        var valid = true
        declarations.forEach { owner ->
            val ownerReference = identityPolicy.identity(owner)
            val serializedNames = owner.serializedFieldNames()
            owner.getAllProperties().forEach property@{ property ->
                val propertyType = property.type.resolve()
                val cardinality =
                    when (propertyType.declaration.qualifiedName?.asString()) {
                        TO_ONE_TYPE -> RelationCardinality.ONE
                        TO_MANY_TYPE -> RelationCardinality.MANY
                        else -> return@property
                    }
                val marker =
                    propertyType.arguments
                        .getOrNull(0)
                        ?.type
                        ?.resolve()
                        ?.declaration as? KSClassDeclaration
                val target =
                    propertyType.arguments
                        .getOrNull(1)
                        ?.type
                        ?.resolve()
                        ?.declaration as? KSClassDeclaration
                if (marker == null || target == null) {
                    logger.error("Relation endpoint arguments must be concrete nominal types.", property)
                    valid = false
                    return@property
                }
                val annotation = marker.annotation<TypewriterRelation>()
                val relationType =
                    marker.getAllSuperTypes().singleOrNull {
                        it.declaration.qualifiedName?.asString() == Relation::class.qualifiedName
                    }
                val sourceDeclaration =
                    relationType
                        ?.arguments
                        ?.getOrNull(0)
                        ?.type
                        ?.resolve()
                        ?.declaration as? KSClassDeclaration
                val targetDeclaration =
                    relationType
                        ?.arguments
                        ?.getOrNull(1)
                        ?.type
                        ?.resolve()
                        ?.declaration as? KSClassDeclaration
                if (annotation == null || sourceDeclaration == null || targetDeclaration == null) {
                    logger.error("Relation markers must declare TypewriterRelation and Relation<Source, Target>.", marker)
                    valid = false
                    return@property
                }
                val id =
                    runCatching { RelationId(annotation.id) }.getOrElse {
                        logger.error(it.message ?: "Invalid relation id.", marker)
                        valid = false
                        return@property
                    }
                val sourceReference = identityPolicy.identity(sourceDeclaration)
                val targetReference = identityPolicy.identity(targetDeclaration)
                val endpointTarget = identityPolicy.identity(target)
                val side =
                    when {
                        ownerReference == sourceReference && endpointTarget == targetReference -> {
                            RelationEndpointSide.SOURCE
                        }

                        ownerReference == targetReference && endpointTarget == sourceReference -> {
                            RelationEndpointSide.TARGET
                        }

                        else -> {
                            logger.error("Relation endpoint owner and target do not match its marker declaration.", property)
                            valid = false
                            return@property
                        }
                    }
                val endpoint =
                    RelationEndpointDefinition(
                        owner = ownerReference,
                        path = DataPath.field(serializedNames[property.simpleName.asString()] ?: property.simpleName.asString()),
                        side = side,
                        cardinality = cardinality,
                    )
                val base =
                    RelationDefinition(
                        id = id,
                        source = sourceReference,
                        target = targetReference,
                        onSourceDelete = annotation.onSourceDelete,
                        onTargetDelete = annotation.onTargetDelete,
                    )
                val current = partials[id]
                if (current != null && current.base != base) {
                    logger.error("Conflicting relation marker declaration $id.", marker)
                    valid = false
                    return@property
                }
                val next = current ?: Partial(base)
                partials[id] =
                    when (side) {
                        RelationEndpointSide.SOURCE -> {
                            if (next.source != null && next.source != endpoint) {
                                logger.error("Relation $id has more than one source endpoint.", property)
                                valid = false
                            }
                            next.copy(source = next.source ?: endpoint)
                        }

                        RelationEndpointSide.TARGET -> {
                            if (next.target != null && next.target != endpoint) {
                                logger.error("Relation $id has more than one target endpoint.", property)
                                valid = false
                            }
                            next.copy(target = next.target ?: endpoint)
                        }
                    }
            }
        }
        if (!valid) return null
        return partials.values
            .map { it.base.copy(sourceEndpoint = it.source, targetEndpoint = it.target) }
            .sortedBy { it.id.value }
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

private fun TypewriterElement.declaredIdentity(): IndexedIdentity? {
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
