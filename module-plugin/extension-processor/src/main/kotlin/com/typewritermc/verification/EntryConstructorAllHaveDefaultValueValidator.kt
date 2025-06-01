package com.typewritermc.verification

import com.google.devtools.ksp.processing.*
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.fullName

class EntryConstructorAllHaveDefaultValueValidator(
    private val logger: KSPLogger
) : SymbolProcessor {
    override fun process(resolver: Resolver): List<KSAnnotated> {
        val entries = resolver.getSymbolsWithAnnotation(Entry::class.qualifiedName!!)
        val invalidEntries = entries
            .filterIsInstance<KSClassDeclaration>()
            .filter { it.classKind == ClassKind.CLASS }
            .flatMap {
                with(logger) {
                    with(resolver) {
                        it.validateConstructor()
                    }
                }
            }
            .toList()

        if (invalidEntries.isEmpty()) return emptyList()
        throw InvalidConstructorDefaultValuesException(invalidEntries)
    }

    context(KSPLogger, Resolver)
    private fun KSClassDeclaration.validateConstructor(): List<String> {
        val primaryConstructor = primaryConstructor
            ?: return listOf("${fullName}: No primary constructor")
        val errors = mutableListOf<String>()

        val invalidParams = primaryConstructor.parameters.filter { it.hasDefault.not() }
        if (invalidParams.isNotEmpty()) {
            errors.add("${fullName}: ${invalidParams.joinToString(", ") { it.name?.asString() ?: "unknown" }}")
        }

        val additionalErrors = primaryConstructor.parameters
            .asSequence()
            .map { it.type.resolve() }
            .flatMap {
                it.shouldCheck()
            }
            .map { it.declaration }
            .filterIsInstance<KSClassDeclaration>()
            .flatMap { it.validateConstructor() }
            .toList()

        errors.addAll(additionalErrors)

        return errors
    }

    context(KSPLogger, Resolver)
    private fun KSType.shouldCheck(): List<KSType> {
        val blueprint = DataBlueprint.blueprint(this) ?: return emptyList()

        if (blueprint is DataBlueprint.ObjectBlueprint) {
            return listOf(this)
        }

        if (blueprint is DataBlueprint.ListBlueprint) {
            val subType = arguments.firstOrNull()?.type?.resolve() ?: return emptyList()
            return subType.shouldCheck()
        }

        if (blueprint is DataBlueprint.MapBlueprint) {
            val key = arguments.firstOrNull()?.type?.resolve()?.shouldCheck() ?: emptyList()
            val value = arguments.lastOrNull()?.type?.resolve()?.shouldCheck() ?: emptyList()

            return key + value
        }

        if (blueprint is DataBlueprint.AlgebraicBlueprint) {
            val classDeclaration = declaration as? KSClassDeclaration ?: return emptyList()
            return classDeclaration.getSealedSubclasses()
                .map { it.asStarProjectedType() }
                .flatMap { it.shouldCheck() }
                .toList()
        }

        if (blueprint is DataBlueprint.CustomBlueprint) {
            if (blueprint.editor == "ref") return emptyList()
            return arguments
                .mapNotNull { it.type?.resolve() }
                .flatMap { it.shouldCheck() }
        }

        return emptyList()
    }
}

class InvalidConstructorDefaultValuesException(entries: List<String>) : Exception(
    """
    |All primary constructor parameters must have default values.
    |The following entries have parameters without default values:
    | - ${entries.joinToString("\n - ")}
    | 
""".trimMargin()
)

class ConstructorDefaultValueValidatorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor {
        return EntryConstructorAllHaveDefaultValueValidator(environment.logger)
    }
}