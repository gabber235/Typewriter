package com.typewritermc.verification

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.isAnnotationPresent
import com.google.devtools.ksp.processing.*
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSValueParameter
import com.typewritermc.core.extension.annotations.Factory
import com.typewritermc.core.extension.annotations.Parameter
import com.typewritermc.processors.fullName
import com.typewritermc.processors.hasParameter
import com.typewritermc.processors.isImplementingInterface
import com.typewritermc.processors.whenClassNameIs
import kotlin.reflect.KClass

class SessionTrackerConstructorValidator(
    private val logger: KSPLogger
) : SymbolProcessor {
    override fun process(resolver: Resolver): List<KSAnnotated> {
        val sessionTrackers = resolver.getSymbolsWithAnnotation(Factory::class.qualifiedName!!)
        val invalidSessionTrackers = sessionTrackers
            .filterIsInstance<KSClassDeclaration>()
            .filter { with(logger) { it.isImplementingInterface("com.typewritermc.engine.paper.interaction.SessionTracker") } }
            .mapNotNull { classDeclaration ->
                val primaryConstructor = classDeclaration.primaryConstructor
                    ?: return@mapNotNull "${classDeclaration.fullName}: No primary constructor"

                val parameters = primaryConstructor.parameters
                val issues = mutableListOf<String>()

                if (!parameters.hasParameter("org.bukkit.entity.Player")) {
                    issues.add("Missing 'player' parameter of type 'org.bukkit.entity.Player'")
                }

                if (!parameters.parameterHasAnnotation("org.bukkit.entity.Player", Parameter::class)) {
                    issues.add("Missing '@Parameter' annotation on parameter of type 'org.bukkit.entity.Player'")
                }

                if (parameters.size != 1) {
                    issues.add("Expected 1 parameter, but got ${parameters.size}")
                }

                if (issues.isNotEmpty()) {
                    "${classDeclaration.fullName}: ${issues.joinToString(", ")}"
                } else {
                    null
                }
            }
            .toList()

        if (invalidSessionTrackers.isEmpty()) return emptyList()
        throw InvalidSessionTrackerConstructorException(invalidSessionTrackers)
    }
}

@OptIn(KspExperimental::class)
private fun List<KSValueParameter>.parameterHasAnnotation(
    parameterClassName: String,
    annotationClass: KClass<out Annotation>
): Boolean {
    return any {
        it.type.resolve().whenClassNameIs(parameterClassName)
                && it.isAnnotationPresent(annotationClass)
    }
}

class InvalidSessionTrackerConstructorException(entries: List<String>) : Exception(
    """
    |Classes annotated with @SessionTracker must have a primary constructor with a 'player' parameter.
    |The following entries have issues:
    | - ${entries.joinToString("\n - ")}
    | 
""".trimMargin()
)

class SessionTrackerConstructorValidatorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor {
        return SessionTrackerConstructorValidator(environment.logger)
    }
}