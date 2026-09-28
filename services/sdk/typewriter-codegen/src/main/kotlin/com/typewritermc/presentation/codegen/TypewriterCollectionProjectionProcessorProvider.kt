package com.typewritermc.presentation.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.STAR
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.presentation.CollectionProjectionProvider
import com.typewritermc.presentation.CollectionProjectionSpec
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.TypewriterCollectionProjection

/** Generates Realm discovery bindings for annotated collection row mappings. */
class TypewriterCollectionProjectionProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterCollectionProjectionProcessor(environment.codeGenerator, environment.logger)
}

private class TypewriterCollectionProjectionProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(TypewriterCollectionProjection::class).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        val functions = symbols.mapNotNull(::projectionFunction).sortedBy { it.qualifiedName?.asString() }
        if (functions.size != symbols.size) return emptyList()
        val bindings = functions.map(::generate)
        val contribution =
            TypeDiscoveryContribution(
                definitions = emptyList(),
                prototypeBindings = emptyList(),
                executableBindings = bindings,
            )
        codeGenerator
            .createNewFile(
                Dependencies(true, *functions.mapNotNull(KSFunctionDeclaration::containingFile).toTypedArray()),
                "META-INF.typewriter.contributions.types",
                "collection-projections",
                "cbor",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(contribution)) }
        generated = true
        return emptyList()
    }

    private fun projectionFunction(symbol: KSAnnotated): KSFunctionDeclaration? {
        val function = symbol as? KSFunctionDeclaration
        if (function == null || function.parentDeclaration != null || Modifier.PRIVATE in function.modifiers ||
            function.parameters.isNotEmpty() ||
            function.returnType
                ?.resolve()
                ?.declaration
                ?.qualifiedName
                ?.asString() != CollectionProjectionSpec::class.qualifiedName
        ) {
            logger.error(
                "TypewriterCollectionProjection requires a visible top level parameterless function returning CollectionProjectionSpec.",
                symbol,
            )
            return null
        }
        return function
    }

    private fun generate(function: KSFunctionDeclaration): ExecutableBinding {
        val functionName = function.simpleName.asString()
        val baseName = functionName.replaceFirstChar(Char::uppercase)
        val moduleName = "${baseName}CollectionProjectionDiscoveryModule"
        val providerName = "${baseName}CollectionProjectionProvider"
        val packageName = function.packageName.asString()
        val moduleClass = ClassName(packageName, moduleName)
        val providerClass = ClassName(packageName, providerName)
        val provider =
            TypeSpec
                .classBuilder(providerName)
                .primaryConstructor(FunSpec.constructorBuilder().addParameter("sourcePart", String::class).build())
                .addSuperinterface(CollectionProjectionProvider::class)
                .addProperty(PropertySpec.builder("sourcePart", String::class, KModifier.OVERRIDE).initializer("sourcePart").build())
                .addProperty(
                    PropertySpec.builder("declarationName", String::class, KModifier.OVERRIDE).initializer("%S", functionName).build(),
                ).addFunction(
                    FunSpec
                        .builder("specification")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("context", PresentationBuildContext::class)
                        .returns(CollectionProjectionSpec::class.asClassName().parameterizedBy(STAR, STAR))
                        .addStatement("return context(context) { %M() }", MemberName(packageName, functionName))
                        .build(),
                ).build()
        val module =
            TypeSpec
                .classBuilder(moduleName)
                .addSuperinterface(GeneratedDiscoveryModule::class)
                .addFunction(
                    FunSpec
                        .builder("module")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("contribution", ContributionKey::class)
                        .returns(org.koin.core.module.Module::class)
                        .addCode(
                            CodeBlock
                                .builder()
                                .add("return module {\n")
                                .indent()
                                .add("single(named(%S)) {\n", "collectionProjection.${providerClass.canonicalName}")
                                .indent()
                                .add("%T(contribution.sourcePart)\n", providerClass)
                                .unindent()
                                .add("} bind %T::class\n", CollectionProjectionProvider::class)
                                .unindent()
                                .add("}\n")
                                .build(),
                        ).build(),
                ).build()
        FileSpec
            .builder(packageName, moduleName)
            .addImport("kotlin", "context")
            .addImport("org.koin.core.qualifier", "named")
            .addImport("org.koin.dsl", "bind", "module")
            .addType(provider)
            .addType(module)
            .build()
            .writeTo(codeGenerator, aggregating = false, originatingKSFiles = listOfNotNull(function.containingFile))
        return ExecutableBinding("collectionProjection.${providerClass.canonicalName}", DiscoveryDomains.Realm, moduleClass.canonicalName)
    }
}
