package com.typewritermc.types.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
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
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.PrototypeBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.types.ConcreteTypePrototype
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.GeneratedTypeGraph
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
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.encodeToByteArray
import kotlin.io.encoding.Base64

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

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(requireNotNull(TypewriterType::class.qualifiedName)).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        if (!validateContextArguments()) return emptyList()

        val declarations = symbols.mapNotNull(::validateDeclaration).sortedBy { it.qualifiedName!!.asString() }
        if (declarations.size != symbols.size) return emptyList()
        val indexed = declarations.associateWith(KSClassDeclaration::typeIdentity)
        val duplicateIds = indexed.entries.groupBy { it.value.id }.filterValues { it.size > 1 }
        duplicateIds.forEach { (id, entries) ->
            entries.forEach { logger.error("Duplicate Typewriter type id $id.", it.key) }
        }
        if (duplicateIds.isNotEmpty()) return emptyList()

        val indexedByName =
            buildMap {
                resolver
                    .getSymbolsWithAnnotation(ELEMENT_ANNOTATION)
                    .filterIsInstance<KSClassDeclaration>()
                    .forEach { declaration ->
                        declaration
                            .annotation(
                                ELEMENT_ANNOTATION,
                            )?.declaredIdentity()
                            ?.let { put(declaration.qualifiedName!!.asString(), it) }
                    }
                indexed.forEach { (declaration, identity) -> put(declaration.qualifiedName!!.asString(), identity) }
            }
        val identityPolicy =
            KspTypeIdentityPolicy { declaration ->
                indexedByName[declaration.qualifiedName?.asString()]?.reference ?: declaration.qualifiedReference()
            }
        val displayNames = indexedByName.map { (name, identity) -> identity.reference to name.substringAfterLast('.') }.toMap()
        val generatedTypes = declarations.mapNotNull { generateType(it, indexed.getValue(it), identityPolicy, displayNames) }
        if (generatedTypes.size != declarations.size) return emptyList()

        writeContribution(generatedTypes)
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
        if (declaration == null || declaration.classKind !in setOf(ClassKind.CLASS, ClassKind.OBJECT) ||
            Modifier.ABSTRACT in declaration.modifiers || Modifier.SEALED in declaration.modifiers
        ) {
            logger.error("TypewriterType may only annotate concrete classes and objects.", symbol)
            return null
        }
        if (Modifier.PRIVATE in declaration.modifiers || declaration.qualifiedName == null) {
            logger.error("Indexed Typewriter types must be visible qualified declarations.", declaration)
            return null
        }
        if (declaration.annotations.none {
                it.annotationType
                    .resolve()
                    .declaration.qualifiedName
                    ?.asString() == SERIALIZABLE_ANNOTATION
            }
        ) {
            logger.error("Indexed Typewriter types must use Kotlin Serializable.", declaration)
            return null
        }
        val annotation = declaration.annotation(requireNotNull(TypewriterType::class.qualifiedName))
        val id = annotation?.stringArgument("id")
        val revision = annotation?.intArgument("revision") ?: 1
        if (id == null || runCatching { DeclaredTypeId.parse(id) }.isFailure) {
            logger.error("Typewriter type ids must contain exactly 32 hexadecimal characters.", declaration)
            return null
        }
        if (revision <= 0) {
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
        return GeneratedType(declaration, graph, generatePrototype(declaration, graph, identity.reference))
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
        val prototype =
            TypeSpec
                .objectBuilder(objectName)
                .superclass(SerializationConcreteTypePrototype::class.asClassName().parameterizedBy(sourceClass))
                .addSuperclassConstructorParameter("%T::class", sourceClass)
                .addSuperclassConstructorParameter("graph.root.let { it as %T.Named }.reference", TypeExpression::class)
                .addSuperclassConstructorParameter("graph.definitions.single { it.id == %L }", reference.code())
                .addSuperclassConstructorParameter("%T.serializer()", sourceClass)
                .build()
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

    private fun writeContribution(types: List<GeneratedType>) {
        val definitions = mergeDefinitions(types.flatMap { it.graph.definitions }) ?: return
        val contribution =
            TypeDiscoveryContribution(
                definitions = definitions,
                prototypeBindings =
                    types.map { generated ->
                        PrototypeBinding(
                            type = (generated.graph.root as TypeExpression.Named).reference,
                            runtimeClass = generated.declaration.qualifiedName!!.asString(),
                            prototypeProviderClass = generated.providerClass.canonicalName,
                            domains = setOf(DiscoveryDomains.Realm, DiscoveryDomains.Execution),
                        )
                    },
                executableBindings = emptyList(),
            )
        val files = types.mapNotNull { it.declaration.containingFile }.toTypedArray()
        codeGenerator
            .createNewFileByPath(
                Dependencies(aggregating = true, *files),
                "META-INF/typewriter/contributions/types/declared.cbor",
                "",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(contribution)) }
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

private data class IndexedIdentity(
    val id: DeclaredTypeId,
    val revision: Int,
) {
    val reference = ResolvedTypeRef(TypeId.Declared(id), revision)
}

private data class GeneratedType(
    val declaration: KSClassDeclaration,
    val graph: TypeGraph,
    val providerClass: ClassName,
)

private fun KSClassDeclaration.typeIdentity(): IndexedIdentity {
    val annotation = requireNotNull(annotation(requireNotNull(TypewriterType::class.qualifiedName)))
    return requireNotNull(annotation.declaredIdentity())
}

private fun KSAnnotation.declaredIdentity(): IndexedIdentity? {
    val id = stringArgument("id")?.let { runCatching { DeclaredTypeId.parse(it) }.getOrNull() } ?: return null
    return IndexedIdentity(id, intArgument("revision") ?: 1)
}

private fun KSClassDeclaration.qualifiedReference(): ResolvedTypeRef {
    val packageName = packageName.asString()
    val name = qualifiedName!!.asString().removePrefix("$packageName.")
    return ResolvedTypeRef(TypeId.Qualified(packageName, name), revision = 1)
}

private fun KSClassDeclaration.annotation(name: String): KSAnnotation? =
    annotations.firstOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == name
    }

private fun KSAnnotation.stringArgument(name: String): String? = arguments.firstOrNull { it.name?.asString() == name }?.value as? String

private fun KSAnnotation.intArgument(name: String): Int? = arguments.firstOrNull { it.name?.asString() == name }?.value as? Int

private fun TypeGraph.withDisplayNames(displayNames: Map<ResolvedTypeRef, String>): TypeGraph =
    copy(
        definitions =
            definitions.map { definition ->
                displayNames[definition.id]?.let { definition.copy(displayName = it) } ?: definition
            },
    )

private fun ResolvedTypeRef.code(): String =
    "com.typewritermc.types.ResolvedTypeRef(" +
        "com.typewritermc.types.TypeId.Declared(" +
        "com.typewritermc.types.DeclaredTypeId.parse(\"${(id as TypeId.Declared).id}\")" +
        "), $revision)"

private const val ARTIFACT_ID_OPTION = "typewriter.artifactId"
private const val SOURCE_PART_OPTION = "typewriter.sourcePart"
private const val SERIALIZABLE_ANNOTATION = "kotlinx.serialization.Serializable"
private const val ELEMENT_ANNOTATION = "com.typewritermc.elements.TypewriterElement"
