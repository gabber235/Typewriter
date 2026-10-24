package com.typewritermc.presentation.codegen

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.isType
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.presentation.TypewriterCollectionProjection
import com.typewritermc.codegen.TypewriterApi as Api

/** Emits the provider of each `@TypewriterCollectionProjection` function, which publishes its specification. */
internal class CollectionProjectionProviderProcessor(
    private val output: GeneratedOutput,
    private val logger: KSPLogger,
) {
    /** Processes this round's projection functions and returns the symbols to defer. */
    fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterCollectionProjection::class).toList()
        symbols.filter(KSAnnotated::validate).forEach(::provide)
        return symbols.filterNot(KSAnnotated::validate)
    }

    private fun provide(symbol: KSAnnotated) {
        val function = symbol as? KSFunctionDeclaration
        if (function == null || function.parentDeclaration != null || Modifier.PRIVATE in function.modifiers) {
            logger.error("Collection projections must be visible top level functions.", symbol)
            return
        }
        if (function.qualifiedName == null || function.parameters.isNotEmpty() || Modifier.SUSPEND in function.modifiers) {
            logger.error("Collection projection functions must be qualified synchronous functions without parameters.", function)
            return
        }
        val returned = function.returnType?.resolve()?.declaration
        if (returned == null || !(returned isType Api.CollectionProjection)) {
            logger.error("Collection projection functions must return CollectionProjection.", function)
            return
        }
        val packageName = function.packageName.asString()
        val name = function.simpleName.asString()
        val provider = ClassName(packageName, name.replaceFirstChar(Char::uppercase) + "GeneratedCollectionProjectionProvider")
        val type =
            TypeSpec
                .classBuilder(provider)
                .addSuperinterface(Api.GeneratedCollectionProjectionProvider)
                .addProperty(
                    PropertySpec
                        .builder("specification", Api.CollectionProjectionSpec, KModifier.OVERRIDE)
                        .getter(FunSpec.getterBuilder().addStatement("return %M().specification", MemberName(packageName, name)).build())
                        .build(),
                ).build()
        output.provide(
            GeneratedFile.builder(packageName, provider.simpleName).addType(type).build(),
            provider,
            GeneratedProviderKind.CollectionProjection,
            function,
        )
    }
}
