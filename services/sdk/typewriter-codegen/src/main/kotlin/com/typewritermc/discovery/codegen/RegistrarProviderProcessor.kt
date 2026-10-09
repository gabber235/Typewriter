package com.typewritermc.discovery.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.typewritermc.codegen.GeneratedProviderContribution
import com.typewritermc.codegen.ProviderProcessingResult
import com.typewritermc.codegen.argument
import com.typewritermc.codegen.rawAnnotation

class RegistrarProviderProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) {
    private val generated = mutableSetOf<String>()

    fun process(resolver: Resolver): ProviderProcessingResult {
        val symbols = resolver.getSymbolsWithAnnotation(TYPEWRITER_REGISTRAR).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        val providers =
            symbols.filter(KSAnnotated::validate).mapNotNull { symbol ->
                val declaration = symbol as? KSClassDeclaration
                if (declaration == null || declaration.classKind != ClassKind.CLASS || Modifier.ABSTRACT in declaration.modifiers) {
                    logger.error("Typewriter registrars must be concrete classes.", symbol)
                    return@mapNotNull null
                }
                val qualified = declaration.qualifiedName?.asString()
                if (qualified == null || Modifier.PRIVATE in declaration.modifiers) {
                    logger.error("Typewriter registrars must be visible qualified declarations.", declaration)
                    return@mapNotNull null
                }
                if (declaration.getAllSuperTypes().none { it.declaration.qualifiedName?.asString() == RUNTIME_REGISTRAR }) {
                    logger.error("Typewriter registrars must implement RuntimeRegistrar.", declaration)
                    return@mapNotNull null
                }
                val annotation = declaration.rawAnnotation(TYPEWRITER_REGISTRAR) ?: return@mapNotNull null
                val id = annotation.argument("id") as? String
                val realm = annotation.argument("realm") as? Boolean ?: false
                val execution = annotation.argument("execution") as? Boolean ?: true
                if (id == null || !id.matches(IDENTIFIER_PATTERN)) {
                    logger.error("Runtime registrar ids must be safe path segments.", declaration)
                    return@mapNotNull null
                }
                if (!realm && !execution) {
                    logger.error("Runtime registrars must select at least one runtime domain.", declaration)
                    return@mapNotNull null
                }
                if (!generated.add(qualified)) return@mapNotNull null
                val packageName = declaration.packageName.asString()
                val providerName = qualified.removePrefix("$packageName.").replace('.', '_') + "GeneratedRegistrarProvider"
                val domains =
                    listOfNotNull(
                        "com.typewritermc.discovery.DiscoveryDomains.Realm".takeIf { realm },
                        "com.typewritermc.discovery.DiscoveryDomains.Execution".takeIf { execution },
                    ).joinToString()
                val source =
                    """
package $packageName

class $providerName : com.typewritermc.discovery.GeneratedRuntimeRegistrarProvider {
    override val descriptor = com.typewritermc.discovery.RuntimeRegistrarDescriptor(
        id = "$id",
        domains = setOf($domains),
    )

    override fun bind(instantiator: com.typewritermc.discovery.GeneratedProviderInstantiator): com.typewritermc.discovery.RuntimeRegistrar =
        instantiator.instantiate($qualified::class.java) as $qualified
}
""".trimStart()
                codeGenerator
                    .createNewFile(
                        Dependencies(false, *listOfNotNull(declaration.containingFile).toTypedArray()),
                        packageName,
                        providerName,
                    ).bufferedWriter()
                    .use { it.write(source) }
                GeneratedProviderContribution("registrar", "$packageName.$providerName")
            }
        return ProviderProcessingResult(providers, deferred)
    }
}

private val IDENTIFIER_PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.]*")
private const val TYPEWRITER_REGISTRAR = "com.typewritermc.discovery.TypewriterRegistrar"
private const val RUNTIME_REGISTRAR = "com.typewritermc.discovery.RuntimeRegistrar"
