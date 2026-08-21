package com.typewritermc.extensions.codegen

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
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.implements
import com.typewritermc.codegen.stringArgument
import com.typewritermc.codegen.toUpperCamelIdentifier
import com.typewritermc.extensions.ExtensionActivator
import com.typewritermc.extensions.TypewriterActivator
import com.typewritermc.imprint.TypewriterActivatorIndex
import com.typewritermc.imprint.TypewriterActivatorReference
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.encodeToByteArray

class ExtensionActivatorProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        ExtensionActivatorProcessor(environment.codeGenerator, environment.logger)
}

@OptIn(ExperimentalSerializationApi::class)
private class ExtensionActivatorProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterActivator::class).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred

        val activators = symbols.mapNotNull(::activator).sortedWith(compareBy(Activator::sourceSet, Activator::id))
        val duplicateIds = activators.groupBy { it.sourceSet to it.id }.filterValues { it.size > 1 }.keys
        duplicateIds.forEach { logger.error("Duplicate activator id ${it.second} in source set ${it.first}.") }
        if (duplicateIds.isNotEmpty()) return emptyList()

        activators.groupBy(Activator::sourceSet).forEach { (sourceSet, entries) ->
            generateActivatorRegistry(sourceSet, entries)
            generateActivatorIndex(sourceSet, entries)
        }
        generated = true
        return emptyList()
    }

    private fun activator(symbol: KSAnnotated): Activator? {
        val declaration = symbol as? KSClassDeclaration
        if (declaration == null || declaration.classKind != ClassKind.CLASS || Modifier.ABSTRACT in declaration.modifiers) {
            logger.error("Typewriter activators must be concrete classes.", symbol)
            return null
        }
        if (!declaration.implements(ExtensionActivator::class)) {
            logger.error("Typewriter activators must implement ExtensionActivator.", declaration)
            return null
        }
        val constructor = declaration.primaryConstructor
        if (constructor != null && constructor.parameters.any { !it.hasDefault }) {
            logger.error("Typewriter activators must have a zero argument constructor.", declaration)
            return null
        }
        if (Modifier.PRIVATE in declaration.modifiers) {
            logger.error("Typewriter activators must be visible to generated code.", declaration)
            return null
        }
        val id = declaration.annotation(TypewriterActivator::class)?.stringArgument("id")
        if (id.isNullOrBlank()) {
            logger.error("Typewriter activator ids must not be blank.", declaration)
            return null
        }
        val sourceSet = declaration.containingFile?.filePath?.sourceSetName()
        if (sourceSet == null) {
            logger.error("Typewriter activators must be declared in a named source set.", declaration)
            return null
        }
        return Activator(sourceSet, id, declaration)
    }

    private fun generateActivatorRegistry(
        sourceSet: String,
        activators: List<Activator>,
    ) {
        val objectName = "${sourceSet.toUpperCamelIdentifier()}ExtensionActivators"
        val initializer =
            activators
                .map { activator -> CodeBlock.of("%T()", activator.declaration.toClassName()) }
                .joinToCode(separator = ",♢", prefix = "listOf(", suffix = ")")
        val registry =
            TypeSpec
                .objectBuilder(objectName)
                .addProperty(
                    PropertySpec
                        .builder(
                            "activators",
                            List::class.asClassName().parameterizedBy(ExtensionActivator::class.asClassName()),
                        ).initializer(initializer)
                        .build(),
                ).build()

        FileSpec
            .builder(GENERATED_PACKAGE, objectName)
            .indent("    ")
            .addType(registry)
            .build()
            .writeTo(
                codeGenerator,
                aggregating = true,
                originatingKSFiles = activators.mapNotNull { it.declaration.containingFile },
            )
    }

    private fun generateActivatorIndex(
        sourceSet: String,
        activators: List<Activator>,
    ) {
        val files = activators.mapNotNull { it.declaration.containingFile }.toTypedArray()
        val index =
            TypewriterActivatorIndex(
                activators =
                    activators.map { activator ->
                        TypewriterActivatorReference(
                            sourceSet = sourceSet,
                            id = activator.id,
                            className = requireNotNull(activator.declaration.qualifiedName).asString(),
                        )
                    },
            )
        codeGenerator
            .createNewFileByPath(
                Dependencies(aggregating = true, *files),
                "META-INF/typewriter/activators/$sourceSet.cbor",
                "",
            ).use { output -> output.write(Cbor.Default.encodeToByteArray(index)) }
    }
}

private data class Activator(
    val sourceSet: String,
    val id: String,
    val declaration: KSClassDeclaration,
)

private fun String.sourceSetName(): String? = replace('\\', '/').substringAfter("/src/", "").substringBefore('/').takeIf(String::isNotBlank)

private const val GENERATED_PACKAGE = "com.typewritermc.extensions.generated"
