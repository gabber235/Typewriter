package com.typewritermc.verification

import com.google.devtools.ksp.processing.*
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.typewritermc.processors.fullName
import com.typewritermc.processors.isImplementingInterface
import kotlin.reflect.KClass

class InterfaceValidator<T : Annotation>(
    private val logger: KSPLogger,
    private val annotationClass: KClass<T>,
    private val interfaceName: String
) : SymbolProcessor {
    override fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(annotationClass.qualifiedName!!)
        val invalidSymbols = symbols
            .filterIsInstance<KSClassDeclaration>()
            .mapNotNull { classDeclaration ->
                context(logger) {
                    if (!classDeclaration.isImplementingInterface(interfaceName)) {
                        "${classDeclaration.fullName}: Does not implement $interfaceName"
                    } else {
                        null
                    }
                }
            }
            .toList()

        if (invalidSymbols.isEmpty()) return emptyList()
        throw InterfaceValidationException(annotationClass.simpleName!!, interfaceName, invalidSymbols)
    }
}


class InterfaceValidationException(annotationName: String, interfaceName: String, entries: List<String>) : Exception(
    """
    |Classes annotated with @$annotationName must implement $interfaceName.
    |The following entries have issues:
    | - ${entries.joinToString("\n - ")}
    |
""".trimMargin()
)

open class InterfaceValidatorProvider<T : Annotation>(
    private val annotationClass: KClass<T>,
    private val interfaceName: String
) : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor {
        return InterfaceValidator(environment.logger, annotationClass, interfaceName)
    }
}
