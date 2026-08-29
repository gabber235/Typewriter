package com.typewritermc.presentation.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
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
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.PresentationSpec
import com.typewritermc.presentation.TypewriterPresentation

class TypewriterPresentationProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterPresentationProcessor(environment.codeGenerator, environment.logger)
}

private class TypewriterPresentationProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(requireNotNull(TypewriterPresentation::class.qualifiedName)).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        val functions = symbols.mapNotNull(::presentationFunction).sortedBy { it.qualifiedName?.asString() }
        if (functions.size != symbols.size) return emptyList()
        val bindings = functions.map(::generate)
        writeContribution(bindings, functions)
        generated = true
        return emptyList()
    }

    private fun presentationFunction(symbol: KSAnnotated): KSFunctionDeclaration? {
        val function = symbol as? KSFunctionDeclaration
        if (function == null || function.parentDeclaration != null) {
            logger.error("TypewriterPresentation may only annotate top level functions.", symbol)
            return null
        }
        if (Modifier.PRIVATE in function.modifiers || function.qualifiedName == null) {
            logger.error("Typewriter presentation functions must be visible and qualified.", function)
            return null
        }
        if (function.parameters.isNotEmpty()) {
            logger.error("Typewriter presentation functions cannot declare value parameters.", function)
            return null
        }
        val declaration =
            function.returnType
                ?.resolve()
                ?.declaration
                ?.qualifiedName
                ?.asString()
        if (declaration != PresentationSpec::class.qualifiedName) {
            logger.error("TypewriterPresentation functions must return PresentationSpec.", function)
            return null
        }
        return function
    }

    private fun generate(function: KSFunctionDeclaration): ExecutableBinding {
        val functionName = function.simpleName.asString()
        val baseName = functionName.replaceFirstChar(Char::uppercase)
        val moduleName = "${baseName}PresentationDiscoveryModule"
        val providerName = "${baseName}PresentationProvider"
        val packageName = function.packageName.asString()
        val moduleClass = ClassName(packageName, moduleName)
        val providerClass = ClassName(packageName, providerName)
        val annotation = requireNotNull(function.annotation(requireNotNull(TypewriterPresentation::class.qualifiedName)))
        val provider =
            TypeSpec
                .classBuilder(providerName)
                .primaryConstructor(
                    FunSpec
                        .constructorBuilder()
                        .addParameter("namespace", String::class)
                        .addParameter("sourcePart", String::class)
                        .build(),
                ).addSuperinterface(PresentationProvider::class)
                .addProperty(
                    PropertySpec
                        .builder("namespace", String::class, KModifier.OVERRIDE)
                        .initializer("namespace")
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("sourcePart", String::class, KModifier.OVERRIDE)
                        .initializer("sourcePart")
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("declarationName", String::class, KModifier.OVERRIDE)
                        .initializer("%S", functionName)
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("default", Boolean::class, KModifier.OVERRIDE)
                        .initializer("%L", annotation.booleanArgument("default") ?: false)
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("priority", Int::class, KModifier.OVERRIDE)
                        .initializer("%L", annotation.intArgument("priority") ?: 0)
                        .build(),
                ).addFunction(
                    FunSpec
                        .builder("specification")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("context", PresentationBuildContext::class)
                        .returns(PresentationSpec::class.asClassName().parameterizedBy(STAR))
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
                                .add("single(named(%S)) {\n", "presentation.${providerClass.canonicalName}")
                                .indent()
                                .add("%T(contribution.origin.value, contribution.sourcePart)\n", providerClass)
                                .unindent()
                                .add("} bind %T::class\n", PresentationProvider::class)
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
        return ExecutableBinding("presentation.${providerClass.canonicalName}", DiscoveryDomains.Realm, moduleClass.canonicalName)
    }

    private fun writeContribution(
        bindings: List<ExecutableBinding>,
        functions: List<KSFunctionDeclaration>,
    ) {
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
                "presentations",
                "cbor",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(contribution)) }
    }
}

private fun KSAnnotated.annotation(qualifiedName: String): KSAnnotation? =
    annotations.firstOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun KSAnnotation.argument(name: String): Any? = arguments.firstOrNull { it.name?.asString() == name }?.value

private fun KSAnnotation.booleanArgument(name: String): Boolean? = argument(name) as? Boolean

private fun KSAnnotation.intArgument(name: String): Int? = argument(name) as? Int
