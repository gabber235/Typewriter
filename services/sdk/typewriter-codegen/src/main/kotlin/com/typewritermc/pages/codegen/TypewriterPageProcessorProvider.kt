package com.typewritermc.pages.codegen

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
import com.squareup.kotlinpoet.AnnotationSpec
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.MemberName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.WildcardTypeName
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.library.PageKind
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.pages.GeneratedPageKind
import com.typewritermc.pages.PageProvider
import com.typewritermc.pages.PageSpec
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.types.DeclaredTypeId

/**
 * KSP entrypoint generating page kind providers and discovery bindings from annotated Kotlin declarations. Each
 * compiler environment receives a fresh processor. Processing defers unresolved symbols, validates supported
 * declaration shapes, and generates its output once for the compilation. Generated resources feed manifest
 * discovery so runtime consumers do not scan source annotations.
 */
class TypewriterPageProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterPageProcessor(environment.codeGenerator, environment.logger)
}

private class TypewriterPageProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(requireNotNull(TypewriterPage::class.qualifiedName)).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        val declarations = symbols.mapNotNull(::pageFunction).sortedBy { it.function.qualifiedName?.asString() }
        if (declarations.size != symbols.size) return emptyList()
        val duplicateIds = declarations.groupBy(PageDeclaration::id).filterValues { it.size > 1 }
        duplicateIds.forEach { (id, values) -> values.forEach { logger.error("Duplicate page id $id.", it.function) } }
        val duplicateMarkers = declarations.groupBy { it.function.packageName.asString() to it.markerName }.filterValues { it.size > 1 }
        duplicateMarkers.forEach { (marker, values) ->
            values.forEach { logger.error("Generated page kind ${marker.second} is declared more than once.", it.function) }
        }
        if (duplicateIds.isNotEmpty() || duplicateMarkers.isNotEmpty()) return emptyList()
        val bindings = declarations.map(::generate)
        writeContribution(bindings, declarations.map(PageDeclaration::function))
        generated = true
        return emptyList()
    }

    private fun pageFunction(symbol: KSAnnotated): PageDeclaration? {
        val function = symbol as? KSFunctionDeclaration
        if (function == null || function.parentDeclaration != null) {
            logger.error("TypewriterPage may only annotate top level functions.", symbol)
            return null
        }
        if (Modifier.PRIVATE in function.modifiers || function.qualifiedName == null) {
            logger.error("Typewriter page functions must be visible and qualified.", function)
            return null
        }
        if (function.parameters.isNotEmpty()) {
            logger.error("Typewriter page functions cannot declare value parameters.", function)
            return null
        }
        val returnType =
            function.returnType
                ?.resolve()
                ?.declaration
                ?.qualifiedName
                ?.asString()
        if (returnType != PageSpec::class.qualifiedName) {
            logger.error("TypewriterPage functions must return PageSpec.", function)
            return null
        }
        val annotation = requireNotNull(function.annotation(requireNotNull(TypewriterPage::class.qualifiedName)))
        val idText = annotation.stringArgument("id")
        val id = idText?.let { runCatching { DeclaredTypeId.parse(it) }.getOrNull() }
        if (id == null) {
            logger.error("Page ids must contain exactly 32 hexadecimal characters.", function)
            return null
        }
        val revision = annotation.intArgument("revision") ?: 1
        if (revision <= 0) {
            logger.error("Page revisions must be positive.", function)
            return null
        }
        val markerName = function.simpleName.asString().replaceFirstChar(Char::uppercase) + "Kind"
        return PageDeclaration(function, id, revision, markerName)
    }

    private fun generate(declaration: PageDeclaration): ExecutableBinding {
        val function = declaration.function
        val functionName = function.simpleName.asString()
        val packageName = function.packageName.asString()
        val markerClass = ClassName(packageName, declaration.markerName)
        val providerName = "${declaration.markerName}PageProvider"
        val moduleName = "${declaration.markerName}PageDiscoveryModule"
        val providerClass = ClassName(packageName, providerName)
        val moduleClass = ClassName(packageName, moduleName)
        val marker =
            TypeSpec
                .objectBuilder(declaration.markerName)
                .addModifiers(KModifier.DATA)
                .addSuperinterface(PageKind::class)
                .addAnnotation(
                    AnnotationSpec
                        .builder(GeneratedPageKind::class)
                        .addMember("id = %S", declaration.id.toString())
                        .addMember("revision = %L", declaration.revision)
                        .build(),
                ).build()
        val provider =
            TypeSpec
                .classBuilder(providerName)
                .primaryConstructor(
                    FunSpec
                        .constructorBuilder()
                        .addParameter("namespace", String::class)
                        .addParameter("sourcePart", String::class)
                        .build(),
                ).addSuperinterface(PageProvider::class)
                .addProperty(
                    PropertySpec
                        .builder("kind", PageKindRef::class, KModifier.OVERRIDE)
                        .initializer(
                            "%T(%T(%T.parse(%S)), %L)",
                            PageKindRef::class,
                            PageKindId::class,
                            DeclaredTypeId::class,
                            declaration.id.toString(),
                            declaration.revision,
                        ).build(),
                ).addProperty(
                    PropertySpec
                        .builder("namespace", String::class, KModifier.OVERRIDE)
                        .initializer("namespace")
                        .build(),
                ).addProperty(
                    PropertySpec
                        .builder("sourcePart", String::class, KModifier.OVERRIDE)
                        .initializer("sourcePart")
                        .build(),
                ).addProperty(stringProperty("declarationName", functionName))
                .addProperty(
                    PropertySpec
                        .builder(
                            "marker",
                            KOTLIN_KCLASS.parameterizedBy(WildcardTypeName.producerOf(PageKind::class.asClassName())),
                            KModifier.OVERRIDE,
                        ).initializer("%T::class", markerClass)
                        .build(),
                ).addFunction(
                    FunSpec
                        .builder("specification")
                        .addModifiers(KModifier.OVERRIDE)
                        .returns(PageSpec::class)
                        .addStatement("return %M()", MemberName(packageName, functionName))
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
                                .add("single(named(%S)) {\n", "page.${providerClass.canonicalName}")
                                .indent()
                                .add("%T(contribution.origin.value, contribution.sourcePart)\n", providerClass)
                                .unindent()
                                .add("} bind %T::class\n", PageProvider::class)
                                .unindent()
                                .add("}\n")
                                .build(),
                        ).build(),
                ).build()
        FileSpec
            .builder(packageName, moduleName)
            .addImport("org.koin.core.qualifier", "named")
            .addImport("org.koin.dsl", "bind", "module")
            .addType(marker)
            .addType(provider)
            .addType(module)
            .build()
            .writeTo(codeGenerator, aggregating = false, originatingKSFiles = listOfNotNull(function.containingFile))
        return ExecutableBinding("page.${providerClass.canonicalName}", DiscoveryDomains.Realm, moduleClass.canonicalName)
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
                "pages",
                "cbor",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(contribution)) }
    }
}

private data class PageDeclaration(
    val function: KSFunctionDeclaration,
    val id: DeclaredTypeId,
    val revision: Int,
    val markerName: String,
)

private fun stringProperty(
    name: String,
    value: String,
): PropertySpec =
    PropertySpec
        .builder(name, String::class, KModifier.OVERRIDE)
        .initializer("%S", value)
        .build()

private fun KSAnnotated.annotation(qualifiedName: String): KSAnnotation? =
    annotations.firstOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun KSAnnotation.argument(name: String): Any? = arguments.firstOrNull { it.name?.asString() == name }?.value

private fun KSAnnotation.stringArgument(name: String): String? = argument(name) as? String

private fun KSAnnotation.intArgument(name: String): Int? = argument(name) as? Int

private val KOTLIN_KCLASS = ClassName("kotlin.reflect", "KClass")
