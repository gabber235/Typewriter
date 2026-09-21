package com.typewritermc.pages.codegen

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
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.codegen.argument
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.rawAnnotation
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.types.DeclaredTypeId

/**
 * KSP entrypoint generating page kind markers, [PageProvider] implementations, and discovery bindings from annotated
 * top level functions. Each generated provider preserves the declaration namespace and source part supplied by the
 * runtime contribution key, then invokes the original function when a page specification is requested. The emitted
 * resource is consumed by manifest discovery, so runtime loading does not scan source annotations.
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
        val symbols = resolver.getSymbolsWithAnnotation(TYPEWRITER_PAGE).toList()
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
        if (returnType != PAGE_SPEC.canonicalName) {
            logger.error("TypewriterPage functions must return PageSpec.", function)
            return null
        }
        val annotation = requireNotNull(function.rawAnnotation(TYPEWRITER_PAGE))
        val idValue = annotation.argument("id") as? String
        val id = idValue?.let { runCatching { DeclaredTypeId.parse(it) }.getOrNull() }
        if (id == null) {
            logger.error("Page ids must contain exactly 32 hexadecimal characters.", function)
            return null
        }
        val revision = annotation.argument("revision") as? Int ?: 1
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
                .addSuperinterface(PAGE_KIND)
                .addAnnotation(
                    AnnotationSpec
                        .builder(GENERATED_PAGE_KIND)
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
                ).addSuperinterface(PAGE_PROVIDER)
                .addProperty(
                    PropertySpec
                        .builder("kind", PAGE_KIND_REF, KModifier.OVERRIDE)
                        .initializer(
                            "%T(%T(%T.parse(%S)), %L)",
                            PAGE_KIND_REF,
                            PAGE_KIND_ID,
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
                            KOTLIN_KCLASS.parameterizedBy(WildcardTypeName.producerOf(PAGE_KIND)),
                            KModifier.OVERRIDE,
                        ).initializer("%T::class", markerClass)
                        .build(),
                ).addFunction(
                    FunSpec
                        .builder("specification")
                        .addModifiers(KModifier.OVERRIDE)
                        .returns(PAGE_SPEC)
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
                                .add("} bind %T::class\n", PAGE_PROVIDER)
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

private val KOTLIN_KCLASS = ClassName("kotlin.reflect", "KClass")
private const val TYPEWRITER_PAGE = "com.typewritermc.pages.TypewriterPage"
private val GENERATED_PAGE_KIND = ClassName("com.typewritermc.pages", "GeneratedPageKind")
private val PAGE_KIND = ClassName("com.typewritermc.library", "PageKind")
private val PAGE_KIND_ID = ClassName("com.typewritermc.library", "PageKindId")
private val PAGE_KIND_REF = ClassName("com.typewritermc.library", "PageKindRef")
private val PAGE_PROVIDER = ClassName("com.typewritermc.pages", "PageProvider")
private val PAGE_SPEC = ClassName("com.typewritermc.pages", "PageSpec")
