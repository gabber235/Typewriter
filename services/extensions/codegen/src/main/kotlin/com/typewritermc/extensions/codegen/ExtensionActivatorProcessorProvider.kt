package com.typewritermc.extensions.codegen

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
import com.google.devtools.ksp.symbol.KSAnnotation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate

class ExtensionActivatorProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        ExtensionActivatorProcessor(environment.codeGenerator, environment.logger)
}

private class ExtensionActivatorProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(ACTIVATOR_ANNOTATION).toList()
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
        val className = declaration.qualifiedName?.asString()
        if (className == null) {
            logger.error("Typewriter activators must have a qualified name.", declaration)
            return null
        }
        val implementsActivator =
            declaration.getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == ACTIVATOR_INTERFACE }
        if (!implementsActivator) {
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
        val annotation =
            declaration.annotations.single {
                it.annotationType
                    .resolve()
                    .declaration.qualifiedName
                    ?.asString() ==
                    ACTIVATOR_ANNOTATION
            }
        val id = annotation.stringArgument("id")
        if (id.isNullOrBlank()) {
            logger.error("Typewriter activator ids must not be blank.", declaration)
            return null
        }
        val sourceSet = declaration.containingFile?.filePath?.sourceSetName()
        if (sourceSet == null) {
            logger.error("Typewriter activators must be declared in a named source set.", declaration)
            return null
        }
        return Activator(sourceSet, id, className, declaration)
    }

    private fun generateActivatorRegistry(
        sourceSet: String,
        activators: List<Activator>,
    ) {
        val objectName = "${sourceSet.identifier()}ExtensionActivators"
        val files = activators.mapNotNull { it.declaration.containingFile }.toTypedArray()
        codeGenerator
            .createNewFile(Dependencies(aggregating = true, *files), GENERATED_PACKAGE, objectName)
            .bufferedWriter()
            .use { writer ->
                writer.appendLine("package $GENERATED_PACKAGE")
                writer.appendLine()
                writer.appendLine("import com.typewritermc.extensions.ExtensionActivator")
                activators.forEachIndexed { index, activator ->
                    writer.appendLine("import ${activator.className} as Activator$index")
                }
                writer.appendLine()
                writer.appendLine("object $objectName {")
                writer.appendLine("    val activators: List<ExtensionActivator> =")
                writer.appendLine("        listOf(")
                activators.forEachIndexed { index, _ -> writer.appendLine("            Activator$index(),") }
                writer.appendLine("        )")
                writer.appendLine("}")
            }
    }

    private fun generateActivatorIndex(
        sourceSet: String,
        activators: List<Activator>,
    ) {
        val files = activators.mapNotNull { it.declaration.containingFile }.toTypedArray()
        codeGenerator
            .createNewFileByPath(
                Dependencies(aggregating = true, *files),
                "META-INF/typewriter/activators/$sourceSet.index",
                "",
            ).bufferedWriter()
            .use { writer ->
                activators.forEach { writer.appendLine("$sourceSet|${it.id}|${it.className}") }
            }
    }
}

private data class Activator(
    val sourceSet: String,
    val id: String,
    val className: String,
    val declaration: KSClassDeclaration,
)

private fun KSAnnotation.stringArgument(name: String): String? = arguments.singleOrNull { it.name?.asString() == name }?.value as? String

private fun String.sourceSetName(): String? = replace('\\', '/').substringAfter("/src/", "").substringBefore('/').takeIf(String::isNotBlank)

private fun String.identifier(): String =
    split(Regex("[^A-Za-z0-9]+"))
        .joinToString("") { it.replaceFirstChar(Char::uppercase) }

private const val ACTIVATOR_ANNOTATION = "com.typewritermc.extensions.TypewriterActivator"
private const val ACTIVATOR_INTERFACE = "com.typewritermc.extensions.ExtensionActivator"
private const val GENERATED_PACKAGE = "com.typewritermc.extensions.generated"
