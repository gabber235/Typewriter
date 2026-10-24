package com.typewritermc.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.symbol.KSDeclaration
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderIndexEntry
import com.typewritermc.discovery.GeneratedProviderKind

/**
 * Writes generated Kotlin files and collects their provider index entries for one KSP compilation.
 *
 * Every provider writes through this owner, so the index cannot drift from the files. Kotlin files are isolating
 * outputs of their originating declaration. The index is written once in [finish] as an aggregating output over all
 * files, because it also lists providers for dependency closure types that have no containing file and providers
 * found by the all files adapter scan.
 */
internal class GeneratedOutput(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val sourcePart: String,
) {
    /** Each written file with the qualified name of the declaration it was generated for. */
    private val written = mutableMapOf<String, String?>()
    private val entries = mutableSetOf<GeneratedProviderIndexEntry>()

    /**
     * Writes [file] once; returns false when this compilation already emitted it in an earlier round, or when another
     * declaration's output already claims the same name, which is reported at [origin].
     */
    fun write(
        file: FileSpec,
        origin: KSDeclaration?,
    ): Boolean {
        val name = "${file.packageName}.${file.name}"
        val owner = origin?.qualifiedName?.asString()
        if (name in written) {
            val claimed = written.getValue(name)
            if (claimed != owner) {
                logger.error("Generated file $name is already generated for $claimed; rename one of the declarations.", origin)
            }
            return false
        }
        written[name] = owner
        file.writeTo(codeGenerator, aggregating = false, originatingKSFiles = listOfNotNull(origin?.containingFile))
        return true
    }

    /** Writes [file] and lists [provider] in the index; a file written in an earlier round is not indexed again. */
    fun provide(
        file: FileSpec,
        provider: ClassName,
        kind: GeneratedProviderKind,
        origin: KSDeclaration?,
    ) {
        if (write(file, origin)) index(provider, kind)
    }

    /** Lists [provider] in the index. Nested providers use their binary name, which the loader resolves. */
    fun index(
        provider: ClassName,
        kind: GeneratedProviderKind,
    ) {
        entries += GeneratedProviderIndexEntry(kind, provider.reflectionName(), sourcePart)
    }

    /** Writes the provider index of everything this compilation provided. */
    fun finish() {
        if (entries.isEmpty()) return
        codeGenerator
            .createNewFileByPath(Dependencies.ALL_FILES, GENERATED_PROVIDER_INDEX_PATH, "")
            .bufferedWriter()
            .use { it.write(GeneratedProviderIndex.render(entries)) }
    }
}
