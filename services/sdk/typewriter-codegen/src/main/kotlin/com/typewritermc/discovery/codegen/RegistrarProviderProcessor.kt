package com.typewritermc.discovery.codegen

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.joinToCode
import com.squareup.kotlinpoet.ksp.toClassName
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.annotation
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.implements
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.RuntimeRegistrarId
import com.typewritermc.discovery.TypewriterRegistrar
import com.typewritermc.codegen.TypewriterApi as Api

/** Emits the provider of each `@TypewriterRegistrar` class, which binds the registrar for its runtime domains. */
internal class RegistrarProviderProcessor(
    private val output: GeneratedOutput,
    private val logger: KSPLogger,
) {
    /** Processes this round's registrars and returns the symbols to defer. */
    fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterRegistrar::class).toList()
        symbols.filter(KSAnnotated::validate).forEach(::provide)
        return symbols.filterNot(KSAnnotated::validate)
    }

    private fun provide(symbol: KSAnnotated) {
        val declaration = symbol as? KSClassDeclaration
        if (declaration == null || declaration.classKind != ClassKind.CLASS || Modifier.ABSTRACT in declaration.modifiers) {
            logger.error("Typewriter registrars must be concrete classes.", symbol)
            return
        }
        if (declaration.qualifiedName == null || Modifier.PRIVATE in declaration.modifiers) {
            logger.error("Typewriter registrars must be visible qualified declarations.", declaration)
            return
        }
        if (!declaration.implements(Api.RuntimeRegistrar)) {
            logger.error("Typewriter registrars must implement RuntimeRegistrar.", declaration)
            return
        }
        val registrar = declaration.annotation<TypewriterRegistrar>() ?: return
        if (!RuntimeRegistrarId.isValid(registrar.id)) {
            logger.error("Runtime registrar ids must be safe path segments.", declaration)
            return
        }
        if (!registrar.realm && !registrar.execution) {
            logger.error("Runtime registrars must select at least one runtime domain.", declaration)
            return
        }
        val registrarClass = declaration.toClassName()
        val provider = ClassName(registrarClass.packageName, registrarClass.simpleNames.joinToString("_") + "GeneratedRegistrarProvider")
        val domains =
            listOfNotNull(
                CodeBlock.of("%T.Realm", DiscoveryDomains::class).takeIf { registrar.realm },
                CodeBlock.of("%T.Execution", DiscoveryDomains::class).takeIf { registrar.execution },
            ).joinToCode(",♢")
        val type =
            TypeSpec
                .classBuilder(provider)
                .addSuperinterface(Api.GeneratedRuntimeRegistrarProvider)
                .addProperty(
                    PropertySpec
                        .builder("descriptor", Api.RuntimeRegistrarDescriptor, KModifier.OVERRIDE)
                        .initializer(
                            "%T(\n⇥id = %T(%S),\ndomains = setOf(%L),\n⇤)",
                            Api.RuntimeRegistrarDescriptor,
                            RuntimeRegistrarId::class,
                            registrar.id,
                            domains,
                        ).build(),
                ).addFunction(
                    FunSpec
                        .builder("bind")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("instantiator", Api.GeneratedProviderInstantiator)
                        .returns(Api.RuntimeRegistrar)
                        .addStatement("return instantiator.instantiate(%T::class.java) as %T", registrarClass, registrarClass)
                        .build(),
                ).build()
        output.provide(
            GeneratedFile.builder(provider.packageName, provider.simpleName).addType(type).build(),
            provider,
            GeneratedProviderKind.Registrar,
            declaration,
        )
    }
}
