package com.typewritermc.elements.codegen

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
import com.typewritermc.codegen.argument
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.rawAnnotation
import com.typewritermc.codegen.stringMapCode
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.PrototypeBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.elements.AvailabilityExpression
import com.typewritermc.elements.Cue
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementDescriptor
import com.typewritermc.elements.ElementDiscoveryContribution
import com.typewritermc.elements.ElementDiscoveryContributionCodec
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPrototype
import com.typewritermc.elements.ElementRuntimeFacet
import com.typewritermc.elements.ElementSearch
import com.typewritermc.elements.ElementSearchDefinition
import com.typewritermc.elements.ElementSearchPropertyOverride
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.Keyframe
import com.typewritermc.elements.Segment
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.elements.TypewriterElementFacet
import com.typewritermc.pages.GeneratedPageKind
import com.typewritermc.types.Color
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.GeneratedTypeGraph
import com.typewritermc.types.Icon
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.SerializationConcreteTypePrototype
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeProvider
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
 * KSP entrypoint generating element prototypes, catalog descriptors, execution facet bindings, and discovery
 * contributions from annotated Kotlin declarations. It converts element schemas, writes generated prototype providers,
 * and emits the catalog and type resources consumed by manifest discovery.
 * [com.typewritermc.discovery.runtime.DiscoveryModuleLoader] later installs execution facet providers, while
 * [com.typewritermc.discovery.runtime.PrototypeRegistryLoader] installs the generated prototypes. Processing defers
 * unresolved symbols, validates supported declaration shapes, and writes once per compilation.
 */
class TypewriterElementProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterElementProcessor(environment.codeGenerator, environment.logger, environment.options)
}

@OptIn(ExperimentalSerializationApi::class)
private class TypewriterElementProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val options: Map<String, String>,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterElement::class).toList()
        val facetSymbols = resolver.getSymbolsWithAnnotation(TypewriterElementFacet::class).toList()
        val deferred = (symbols + facetSymbols).filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return (symbols + facetSymbols).distinct()
        if (!validateContextArguments()) return emptyList()

        val elements = symbols.mapNotNull(::element).sortedBy { it.declaration.qualifiedName!!.asString() }
        if (elements.size != symbols.size) return emptyList()
        val duplicateIds = elements.groupBy(ElementDeclaration::id).filterValues { it.size > 1 }
        duplicateIds.forEach { (id, entries) -> entries.forEach { logger.error("Duplicate element id $id.", it.declaration) } }
        if (duplicateIds.isNotEmpty()) return emptyList()

        val indexedByName =
            buildMap<String, ResolvedTypeRef> {
                resolver
                    .getSymbolsWithAnnotation(TypewriterType::class)
                    .filterIsInstance<KSClassDeclaration>()
                    .forEach { declaration -> declaration.declaredTypeReference()?.let { put(declaration.qualifiedName!!.asString(), it) } }
                resolver
                    .getSymbolsWithAnnotation(GeneratedPageKind::class)
                    .filterIsInstance<KSClassDeclaration>()
                    .forEach { declaration ->
                        declaration.generatedPageKindReference()?.let {
                            put(declaration.qualifiedName!!.asString(), it)
                        }
                    }
                elements.forEach { element -> put(element.declaration.qualifiedName!!.asString(), element.reference) }
            }
        val identityPolicy =
            KspTypeIdentityPolicy { declaration ->
                indexedByName[declaration.qualifiedName?.asString()] ?: declaration.qualifiedReference()
            }
        val displayNames = indexedByName.map { (name, reference) -> reference to name.substringAfterLast('.') }.toMap()
        val generatedElements = elements.mapNotNull { generate(it, identityPolicy, displayNames) }
        if (generatedElements.size != elements.size) return emptyList()
        val facets = facetSymbols.mapNotNull(::facet).sortedBy { it.elementType.value.toString() }
        if (facets.size != facetSymbols.size) return emptyList()
        writeContributions(generatedElements, facets)
        generated = true
        return emptyList()
    }

    private fun facet(symbol: KSAnnotated): GeneratedFacet? {
        val declaration = symbol as? KSClassDeclaration
        if (declaration == null || declaration.classKind != ClassKind.CLASS || Modifier.ABSTRACT in declaration.modifiers) {
            logger.error("Typewriter element facets must be concrete classes.", symbol)
            return null
        }
        if (Modifier.PRIVATE in declaration.modifiers || declaration.qualifiedName == null) {
            logger.error("Typewriter element facets must be visible qualified declarations.", declaration)
            return null
        }
        val facetName = requireNotNull(ElementRuntimeFacet::class.qualifiedName)
        if (declaration.getAllSuperTypes().none { it.declaration.qualifiedName?.asString() == facetName }) {
            logger.error("Typewriter element facets must implement ElementRuntimeFacet.", declaration)
            return null
        }
        val rawAnnotation = requireNotNull(declaration.rawAnnotation(TypewriterElementFacet::class))
        val elementDeclaration =
            (
                rawAnnotation.argument(
                    "element",
                ) as? com.google.devtools.ksp.symbol.KSType
            )?.declaration as? KSClassDeclaration
        val elementAnnotation = elementDeclaration?.annotation<TypewriterElement>()
        val elementId = elementAnnotation?.let { runCatching { DeclaredTypeId.parse(it.id) }.getOrNull() }
        if (elementId == null) {
            logger.error("Typewriter element facets must target a TypewriterElement declaration.", declaration)
            return null
        }
        return GeneratedFacet(ElementTypeId(elementId), generateFacetProvider(declaration), declaration)
    }

    private fun generateFacetProvider(declaration: KSClassDeclaration): ClassName {
        val providerName = "${declaration.simpleName.asString()}DiscoveryModuleProvider"
        val providerClass = ClassName(declaration.packageName.asString(), providerName)
        val provider =
            TypeSpec
                .classBuilder(providerName)
                .addSuperinterface(GeneratedDiscoveryModule::class)
                .addFunction(
                    FunSpec
                        .builder("module")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("contribution", ContributionKey::class)
                        .returns(org.koin.core.module.Module::class)
                        .addCode(
                            "return module {\n" +
                                "    singleOf(::%T).bind<%T<*>>()\n" +
                                "}\n",
                            declaration.toClassName(),
                            ElementRuntimeFacet::class,
                        ).build(),
                ).build()
        FileSpec
            .builder(declaration.packageName.asString(), providerName)
            .addImport("org.koin.core.module.dsl", "singleOf")
            .addImport("org.koin.dsl", "bind", "module")
            .addType(provider)
            .build()
            .writeTo(codeGenerator, aggregating = false, originatingKSFiles = listOfNotNull(declaration.containingFile))
        return providerClass
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

    private fun element(symbol: KSAnnotated): ElementDeclaration? {
        val declaration = symbol as? KSClassDeclaration
        if (declaration == null || declaration.classKind !in setOf(ClassKind.CLASS, ClassKind.OBJECT) ||
            Modifier.ABSTRACT in declaration.modifiers || Modifier.SEALED in declaration.modifiers
        ) {
            logger.error("TypewriterElement may only annotate concrete classes and objects.", symbol)
            return null
        }
        if (declaration.annotation<TypewriterType>() != null) {
            logger.error("TypewriterElement and TypewriterType cannot annotate the same declaration.", declaration)
            return null
        }
        val superTypes = declaration.getAllSuperTypes().mapNotNull { it.declaration.qualifiedName?.asString() }.toSet()
        if (Element::class.qualifiedName !in superTypes) {
            logger.error("Typewriter elements must implement Element.", declaration)
            return null
        }
        val isCue = Cue::class.qualifiedName in superTypes
        val isSegment = Segment::class.qualifiedName in superTypes
        val isKeyframe = Keyframe::class.qualifiedName in superTypes
        if (isCue && isSegment == isKeyframe) {
            logger.error("Cue elements must implement exactly one of Segment or Keyframe.", declaration)
            return null
        }
        val annotation = requireNotNull(declaration.annotation<TypewriterElement>())
        val id = runCatching { DeclaredTypeId.parse(annotation.id) }.getOrNull()
        if (id == null) {
            logger.error("Element ids must contain exactly 32 hexadecimal characters.", declaration)
            return null
        }
        val revision = annotation.revision
        if (revision <= 0) {
            logger.error("Element type revisions must be positive.", declaration)
            return null
        }
        val name = annotation.name
        val description = annotation.description
        val icon =
            runCatching { Icon.parse(annotation.icon) }
                .getOrElse {
                    logger.error(it.message ?: "Invalid element icon.", declaration)
                    return null
                }
        val color =
            runCatching { Color.parseRgb(annotation.color) }
                .getOrElse {
                    logger.error(it.message ?: "Invalid element color.", declaration)
                    return null
                }
        val descriptor =
            runCatching {
                ElementDescriptor(
                    id = ElementTypeId(id),
                    type = ResolvedTypeRef(TypeId.Declared(id), revision),
                    name = name,
                    description = description,
                    icon = icon,
                    color = color,
                    availability = AvailabilityExpression.Always,
                )
            }.getOrElse {
                logger.error(it.message ?: "Invalid element descriptor.", declaration)
                return null
            }
        return ElementDeclaration(declaration, id, descriptor)
    }

    private fun generate(
        element: ElementDeclaration,
        identityPolicy: KspTypeIdentityPolicy,
        displayNames: Map<ResolvedTypeRef, String>,
    ): GeneratedElement? {
        val conversion = KspTypeGraphConverter(identityPolicy).convert(element.declaration.asStarProjectedType())
        val successfulConversion =
            when (conversion) {
                is KspTypeConversionResult.Success -> {
                    conversion
                }

                is KspTypeConversionResult.Failure -> {
                    conversion.diagnostics.forEach { logger.error(it.toString(), element.declaration) }
                    return null
                }
            }
        val graph = successfulConversion.graph.withDisplayNames(displayNames)
        if ((graph.root as? TypeExpression.Named)?.reference != element.reference) {
            logger.error("Element type graph root did not retain its declared identity.", element.declaration)
            return null
        }
        val rootProperties =
            successfulConversion.serializedProperties.filter { it.ownerType == element.reference }
        if (!validateRequiredProperty(element, rootProperties, "id", ElementInstanceId::class.qualifiedName!!)) return null
        if (!validateRequiredProperty(element, rootProperties, "name", String::class.qualifiedName!!)) return null
        val overrideDeclarations =
            successfulConversion.serializedProperties.mapNotNull { property ->
                property.declaration.annotation<ElementSearch>()?.let { annotation ->
                    ElementSearchPropertyOverride(property.ownerType, property.serializedName, annotation.mode) to
                        property.declaration
                }
            }
        val reservedOverrides =
            overrideDeclarations.filter { (override, _) ->
                override.ownerType == element.reference && override.field in setOf("id", "name")
            }
        if (reservedOverrides.isNotEmpty()) {
            reservedOverrides.forEach { (_, declaration) ->
                logger.error("Element id and name fields have fixed search behavior.", declaration)
            }
            return null
        }
        val searchDefinition =
            when (
                val result =
                    ElementSearchDefinitionGenerator.generate(
                        graph,
                        overrideDeclarations.map { it.first } +
                            listOf(
                                ElementSearchPropertyOverride(
                                    element.reference,
                                    "id",
                                    com.typewritermc.elements.ElementSearchMode.NONE,
                                ),
                                ElementSearchPropertyOverride(
                                    element.reference,
                                    "name",
                                    com.typewritermc.elements.ElementSearchMode.NONE,
                                ),
                            ),
                    )
            ) {
                is ElementSearchGenerationResult.Success -> {
                    result.definition
                }

                is ElementSearchGenerationResult.InvalidOverrides -> {
                    result.overrides.forEach { invalid ->
                        val declaration = overrideDeclarations.single { it.first == invalid }.second
                        logger.error(
                            "Element search mode ${invalid.mode} requires a text leaf outside reference values.",
                            declaration,
                        )
                    }
                    return null
                }
            }
        val searchableElement = element.copy(descriptor = element.descriptor.copy(searchDefinition = searchDefinition))
        return GeneratedElement(searchableElement, graph, generatePrototype(searchableElement, graph))
    }

    private fun validateRequiredProperty(
        element: ElementDeclaration,
        properties: List<com.typewritermc.types.ksp.KspSerializedProperty>,
        name: String,
        expectedType: String,
    ): Boolean {
        val matches = properties.filter { it.serializedName == name }
        val actualType =
            matches
                .singleOrNull()
                ?.declaration
                ?.type
                ?.resolve()
                ?.declaration
                ?.qualifiedName
                ?.asString()
        if (actualType == expectedType) return true
        logger.error(
            "Typewriter elements must serialize '$name' as $expectedType.",
            matches.singleOrNull()?.declaration ?: element.declaration,
        )
        return false
    }

    private fun generatePrototype(
        element: ElementDeclaration,
        graph: TypeGraph,
    ): ClassName {
        val declaration = element.declaration
        val sourceClass = declaration.toClassName()
        val objectName = "${declaration.simpleName.asString()}ElementPrototype"
        val providerName = "${objectName}Provider"
        val packageName = declaration.packageName.asString()
        val encodedGraph = Base64.encode(Cbor.Default.encodeToByteArray(graph))
        val prototype =
            TypeSpec
                .objectBuilder(objectName)
                .superclass(SerializationConcreteTypePrototype::class.asClassName().parameterizedBy(sourceClass))
                .addSuperinterface(ElementPrototype::class.asClassName().parameterizedBy(sourceClass))
                .addSuperclassConstructorParameter("%T::class", sourceClass)
                .addSuperclassConstructorParameter("graph.root.let { it as %T.Named }.reference", TypeExpression::class)
                .addSuperclassConstructorParameter("graph.definitions.single { it.id == %L }", element.reference.code())
                .addSuperclassConstructorParameter("%T.serializer()", sourceClass)
                .addSuperclassConstructorParameter("%L", declaration.serializedFieldNames().stringMapCode())
                .addProperty(
                    PropertySpec
                        .builder("descriptor", ElementDescriptor::class)
                        .addModifiers(KModifier.OVERRIDE)
                        .initializer(element.descriptor.code())
                        .build(),
                ).build()
        val provider =
            TypeSpec
                .classBuilder(providerName)
                .addSuperinterface(TypePrototypeProvider::class)
                .addFunction(
                    FunSpec
                        .builder("prototype")
                        .addModifiers(KModifier.OVERRIDE)
                        .returns(ConcreteTypePrototype::class.asClassName().parameterizedBy(STAR))
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

    private fun writeContributions(
        elements: List<GeneratedElement>,
        facets: List<GeneratedFacet>,
    ) {
        val files =
            (
                elements.mapNotNull { it.element.declaration.containingFile } +
                    facets.mapNotNull { it.declaration.containingFile }
            ).distinct().toTypedArray()
        val definitions = mergeDefinitions(elements.flatMap { it.graph.definitions }) ?: return
        val typeContribution =
            TypeDiscoveryContribution(
                definitions = definitions,
                prototypeBindings =
                    elements.map { generated ->
                        PrototypeBinding(
                            type = generated.element.reference,
                            runtimeClass =
                                generated.element.declaration.qualifiedName!!
                                    .asString(),
                            prototypeProviderClass = generated.providerClass.canonicalName,
                            domains = setOf(DiscoveryDomains.Realm, DiscoveryDomains.Execution),
                        )
                    },
                executableBindings = facets.map(GeneratedFacet::executableBinding),
            )
        val elementContribution =
            ElementDiscoveryContribution(
                descriptors = elements.map { it.element.descriptor },
            )
        codeGenerator
            .createNewFileByPath(
                Dependencies(aggregating = true, *files),
                "META-INF/typewriter/contributions/types/elements.cbor",
                "",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(typeContribution)) }
        codeGenerator
            .createNewFileByPath(
                Dependencies(aggregating = true, *files),
                "META-INF/typewriter/contributions/elements/catalog.cbor",
                "",
            ).use { it.write(ElementDiscoveryContributionCodec.encode(elementContribution)) }
    }

    private fun mergeDefinitions(definitions: List<TypeDefinition>): List<TypeDefinition>? {
        val merged = linkedMapOf<ResolvedTypeRef, TypeDefinition>()
        definitions.sortedBy { it.id.toString() }.forEach { definition ->
            val previous = merged.putIfAbsent(definition.id, definition)
            if (previous != null && previous != definition) {
                logger.error("Conflicting generated type definition ${definition.id}.")
                return null
            }
        }
        return merged.values.toList()
    }
}

private data class ElementDeclaration(
    val declaration: KSClassDeclaration,
    val id: DeclaredTypeId,
    val descriptor: ElementDescriptor,
) {
    val reference: ResolvedTypeRef = descriptor.type
}

private data class GeneratedElement(
    val element: ElementDeclaration,
    val graph: TypeGraph,
    val providerClass: ClassName,
)

private data class GeneratedFacet(
    val elementType: ElementTypeId,
    val providerClass: ClassName,
    val declaration: KSClassDeclaration,
) {
    fun executableBinding(): ExecutableBinding =
        ExecutableBinding("facet.${elementType.value}", DiscoveryDomains.Execution, providerClass.canonicalName)
}

private fun KSClassDeclaration.qualifiedReference(): ResolvedTypeRef {
    val packageName = packageName.asString()
    val name = qualifiedName!!.asString().removePrefix("$packageName.")
    return ResolvedTypeRef(TypeId.Qualified(packageName, name), revision = 1)
}

private fun KSClassDeclaration.declaredTypeReference(): ResolvedTypeRef? {
    val annotation = annotation<TypewriterType>() ?: return null
    val id = runCatching { DeclaredTypeId.parse(annotation.id) }.getOrNull() ?: return null
    return ResolvedTypeRef(TypeId.Declared(id), annotation.revision)
}

private fun KSClassDeclaration.generatedPageKindReference(): ResolvedTypeRef? {
    val annotation = annotation<GeneratedPageKind>() ?: return null
    val id = runCatching { DeclaredTypeId.parse(annotation.id) }.getOrNull() ?: return null
    return ResolvedTypeRef(TypeId.Declared(id), annotation.revision)
}

private fun TypeGraph.withDisplayNames(displayNames: Map<ResolvedTypeRef, String>): TypeGraph =
    copy(
        definitions =
            definitions.map { definition ->
                displayNames[definition.id]?.let { definition.copy(displayName = it) } ?: definition
            },
    )

private fun ResolvedTypeRef.code(): String =
    "com.typewritermc.types.ResolvedTypeRef(" +
        "${id.code()}, $revision)"

private fun TypeId.code(): String =
    when (this) {
        is TypeId.Builtin -> {
            "com.typewritermc.types.TypeId.Builtin(com.typewritermc.types.BuiltinTypeId.$id)"
        }

        is TypeId.Declared -> {
            "com.typewritermc.types.TypeId.Declared(" +
                "com.typewritermc.types.DeclaredTypeId.parse(\"$id\"))"
        }

        is TypeId.Qualified -> {
            "com.typewritermc.types.TypeId.Qualified(\"${namespace.escape()}\", \"${name.escape()}\")"
        }
    }

private fun ElementDescriptor.code(): String =
    "com.typewritermc.elements.ElementDescriptor(" +
        "com.typewritermc.elements.ElementTypeId(" +
        "com.typewritermc.types.DeclaredTypeId.parse(\"${id.value}\")" +
        "), " +
        "${type.code()}, " +
        "\"${name.escape()}\", " +
        "\"${description.escape()}\", " +
        "${icon.code()}, " +
        "com.typewritermc.types.Color(${color.argb}u), " +
        "com.typewritermc.elements.AvailabilityExpression.Always, " +
        "${searchDefinition?.code() ?: "null"})"

private fun ElementSearchDefinition.code(): String =
    "com.typewritermc.elements.ElementSearchDefinition(" +
        "com.typewritermc.elements.ElementSearchPolicy.$policy, " +
        propertyOverrides.joinToString(", ", "listOf(", "), ") { it.code() } +
        revisionFingerprintInputs.joinToString(", ", "listOf(", ")") { it.code() } +
        ")"

private fun ElementSearchPropertyOverride.code(): String =
    "com.typewritermc.elements.ElementSearchPropertyOverride(" +
        "${ownerType.code()}, \"${field.escape()}\", " +
        "com.typewritermc.elements.ElementSearchMode.$mode)"

private fun Icon.code(): String =
    when (this) {
        is Icon.Iconify -> "com.typewritermc.types.Icon.Iconify(\"${value.escape()}\")"
        is Icon.Svg -> "com.typewritermc.types.Icon.Svg(\"${source.escape()}\")"
    }

private fun String.escape(): String = replace("\\", "\\\\").replace("\"", "\\\"")

private const val ARTIFACT_ID_OPTION = "typewriter.artifactId"
private const val SOURCE_PART_OPTION = "typewriter.sourcePart"
