package com.typewritermc.formula.codegen

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.ksp.toClassName
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.formula.TypewriterDynamicProvider
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Emits one `GeneratedDynamicProvider` for each `@TypewriterDynamicProvider` object. The provider registers through
 * the object, the same adapter a check provider gets, so the realm collects hooks the way it collects checks.
 */
internal class DynamicProviderProcessor(
    private val output: GeneratedOutput,
    private val logger: KSPLogger,
) {
    /** Processes this round's dynamic providers and returns the symbols to defer. */
    fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterDynamicProvider::class).toList()
        symbols.filter(KSAnnotated::validate).forEach(::provide)
        return symbols.filterNot(KSAnnotated::validate)
    }

    private fun provide(symbol: KSAnnotated) {
        val owner = symbol as? KSClassDeclaration
        if (owner == null || owner.classKind != ClassKind.OBJECT) {
            logger.error("A dynamic provider must be an object.", symbol)
            return
        }
        if (owner.qualifiedName == null || Modifier.PRIVATE in owner.modifiers) {
            logger.error("A dynamic provider must be visible.", owner)
            return
        }
        val ownerClass = owner.toClassName()
        val providerClass = ClassName(ownerClass.packageName, "${ownerClass.simpleNames.joinToString("")}GeneratedDynamicProvider")
        val type =
            TypeSpec
                .classBuilder(providerClass)
                .addSuperinterface(Api.GeneratedDynamicProvider)
                .addFunction(
                    FunSpec
                        .builder("register")
                        .addModifiers(KModifier.OVERRIDE)
                        .receiver(Api.Dynamics)
                        .addStatement("with(%T) { this@register.register() }", ownerClass)
                        .build(),
                ).build()
        output.provide(
            GeneratedFile.builder(providerClass.packageName, providerClass.simpleName).addType(type).build(),
            providerClass,
            GeneratedProviderKind.Dynamic,
            owner,
        )
    }
}
