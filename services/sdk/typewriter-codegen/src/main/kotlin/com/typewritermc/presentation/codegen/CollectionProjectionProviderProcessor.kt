package com.typewritermc.presentation.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.typewritermc.codegen.GeneratedProviderContribution
import com.typewritermc.codegen.ProviderProcessingResult

class CollectionProjectionProviderProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) {
    private val generated = mutableSetOf<String>()

    fun process(resolver: Resolver): ProviderProcessingResult {
        val symbols = resolver.getSymbolsWithAnnotation(TYPEWRITER_COLLECTION_PROJECTION).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        val providers =
            symbols.filter(KSAnnotated::validate).mapNotNull { symbol ->
                val function = symbol as? KSFunctionDeclaration
                if (function == null || function.parentDeclaration != null || Modifier.PRIVATE in function.modifiers) {
                    logger.error("Collection projections must be visible top level functions.", symbol)
                    return@mapNotNull null
                }
                val qualified = function.qualifiedName?.asString()
                if (qualified == null || function.parameters.isNotEmpty() || Modifier.SUSPEND in function.modifiers) {
                    logger.error("Collection projection functions must be qualified synchronous functions without parameters.", function)
                    return@mapNotNull null
                }
                if (function.returnType
                        ?.resolve()
                        ?.declaration
                        ?.qualifiedName
                        ?.asString() != COLLECTION_PROJECTION
                ) {
                    logger.error("Collection projection functions must return CollectionProjection.", function)
                    return@mapNotNull null
                }
                if (!generated.add(qualified)) return@mapNotNull null
                val packageName = function.packageName.asString()
                val providerName =
                    function.simpleName.asString().replaceFirstChar(Char::uppercase) + "GeneratedCollectionProjectionProvider"
                val providerClass = "$packageName.$providerName"
                val source =
                    """
package $packageName

class $providerName : com.typewritermc.discovery.GeneratedCollectionProjectionProvider {
    override val specification: com.typewritermc.presentation.CollectionProjectionSpec
        get() = ${function.simpleName.asString()}().specification
}
""".trimStart()
                codeGenerator
                    .createNewFile(
                        Dependencies(false, *listOfNotNull(function.containingFile).toTypedArray()),
                        packageName,
                        providerName,
                    ).bufferedWriter()
                    .use { it.write(source) }
                GeneratedProviderContribution("collectionProjection", providerClass)
            }
        return ProviderProcessingResult(providers, deferred)
    }
}

private const val TYPEWRITER_COLLECTION_PROJECTION =
    "com.typewritermc.presentation.TypewriterCollectionProjection"
private const val COLLECTION_PROJECTION = "com.typewritermc.presentation.CollectionProjection"
