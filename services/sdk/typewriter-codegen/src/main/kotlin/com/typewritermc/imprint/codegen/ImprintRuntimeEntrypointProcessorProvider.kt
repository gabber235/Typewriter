package com.typewritermc.imprint.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.getConstructors
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
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.imprint.HostedRuntimeEntrypointMetadata
import com.typewritermc.imprint.HostedRuntimeEntrypointMetadataCodec
import com.typewritermc.imprint.IMPRINT_RUNTIME_ENTRYPOINTS_PATH
import com.typewritermc.imprint.ImprintRuntimeEntrypoint

/** Generates the intermediate metadata used to place a hosted runtime entrypoint in its canonical manifest. */
class ImprintRuntimeEntrypointProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        ImprintRuntimeEntrypointProcessor(environment.codeGenerator, environment.logger)
}

private class ImprintRuntimeEntrypointProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(ImprintRuntimeEntrypoint::class).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        val declarations = symbols.mapNotNull(::entrypoint).sortedBy { it.qualifiedName?.asString() }
        if (declarations.size != symbols.size) return emptyList()
        writeMetadata(declarations)
        generated = true
        return emptyList()
    }

    private fun entrypoint(symbol: KSAnnotated): KSClassDeclaration? {
        val declaration = symbol as? KSClassDeclaration
        if (declaration == null || declaration.classKind != ClassKind.CLASS || Modifier.ABSTRACT in declaration.modifiers) {
            logger.error("Imprint runtime entrypoints must be concrete classes.", symbol)
            return null
        }
        if (Modifier.PRIVATE in declaration.modifiers || declaration.qualifiedName == null || declaration.parentDeclaration != null) {
            logger.error("Imprint runtime entrypoints must be visible qualified declarations.", declaration)
            return null
        }
        if (declaration.getAllSuperTypes().none { it.declaration.qualifiedName?.asString() == HOSTED_RUNTIME_ENTRYPOINT }) {
            logger.error("Imprint runtime entrypoints must implement HostedRuntimeEntrypoint.", declaration)
            return null
        }
        if (
            declaration.getConstructors().none { constructor ->
                Modifier.PRIVATE !in constructor.modifiers && constructor.parameters.all { it.hasDefault }
            }
        ) {
            logger.error("Imprint runtime entrypoints must have a public zero argument constructor.", declaration)
            return null
        }
        return declaration
    }

    private fun writeMetadata(declarations: List<KSClassDeclaration>) {
        val files = declarations.mapNotNull { it.containingFile }.toTypedArray()
        val metadata = HostedRuntimeEntrypointMetadata(declarations.map { requireNotNull(it.qualifiedName).asString() })
        codeGenerator
            .createNewFileByPath(Dependencies(aggregating = true, *files), IMPRINT_RUNTIME_ENTRYPOINTS_PATH, "")
            .use { it.write(HostedRuntimeEntrypointMetadataCodec.encode(metadata)) }
    }
}

private const val HOSTED_RUNTIME_ENTRYPOINT = "com.typewritermc.loader.api.HostedRuntimeEntrypoint"
