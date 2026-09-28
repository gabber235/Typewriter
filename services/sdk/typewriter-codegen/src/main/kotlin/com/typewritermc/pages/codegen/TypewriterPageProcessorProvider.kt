package com.typewritermc.pages.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.KSType
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
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.WildcardTypeName
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.codegen.argument
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.rawAnnotation
import com.typewritermc.codegen.annotation
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.TypewriterType

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
        val duplicateTypes = declarations.groupBy { it.pageType.qualifiedName?.asString() }.filterValues { it.size > 1 }
        duplicateTypes.forEach { (type, values) ->
            values.forEach { logger.error("Page type $type has more than one editor specification.", it.function) }
        }
        if (duplicateIds.isNotEmpty() || duplicateTypes.isNotEmpty()) return emptyList()
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
        val pageType = (annotation.argument("type") as? KSType)?.declaration as? KSClassDeclaration
        if (pageType == null || !pageType.implementsPage()) {
            logger.error("TypewriterPage must name a concrete Page type.", function)
            return null
        }
        val typeAnnotation = pageType.annotation<TypewriterType>()
        val id = typeAnnotation?.id?.let { runCatching { DeclaredTypeId.parse(it) }.getOrNull() }
        if (id == null || typeAnnotation.revision <= 0) {
            logger.error("Page type must have a valid TypewriterType identity.", pageType)
            return null
        }
        return PageDeclaration(function, pageType, id, typeAnnotation.revision)
    }

    private fun KSClassDeclaration.implementsPage(): Boolean =
        modifiers.contains(Modifier.DATA) &&
            getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == "com.typewritermc.library.Page" }

    private fun generate(declaration: PageDeclaration): ExecutableBinding {
        val function = declaration.function
        val functionName = function.simpleName.asString()
        val packageName = function.packageName.asString()
        val markerClass = declaration.pageType.toClassName()
        val providerName = "${functionName.replaceFirstChar(Char::uppercase)}PageProvider"
        val moduleName = "${functionName.replaceFirstChar(Char::uppercase)}PageDiscoveryModule"
        val providerClass = ClassName(packageName, providerName)
        val moduleClass = ClassName(packageName, moduleName)
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
                        .builder("type", RESOLVED_TYPE_REF, KModifier.OVERRIDE)
                        .initializer(
                            "%T(%T.Declared(%T.parse(%S)), %L)",
                            RESOLVED_TYPE_REF,
                            TYPE_ID,
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
                            KOTLIN_KCLASS.parameterizedBy(WildcardTypeName.producerOf(PAGE)),
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
    val pageType: KSClassDeclaration,
    val id: DeclaredTypeId,
    val revision: Int,
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
private val PAGE = ClassName("com.typewritermc.library", "Page")
private val RESOLVED_TYPE_REF = ClassName("com.typewritermc.types", "ResolvedTypeRef")
private val TYPE_ID = ClassName("com.typewritermc.types", "TypeId")
private val PAGE_PROVIDER = ClassName("com.typewritermc.pages", "PageProvider")
private val PAGE_SPEC = ClassName("com.typewritermc.pages", "PageSpec")
