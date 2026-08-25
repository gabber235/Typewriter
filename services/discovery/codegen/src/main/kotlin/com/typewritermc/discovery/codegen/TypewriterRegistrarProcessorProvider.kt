package com.typewritermc.discovery.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.ClassKind
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FileSpec
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.discovery.runtime.RuntimeRegistrar
import com.typewritermc.discovery.runtime.TypewriterRegistrar

class TypewriterRegistrarProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterRegistrarProcessor(environment.codeGenerator, environment.logger, environment.options)
}

private class TypewriterRegistrarProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val options: Map<String, String>,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val symbols = resolver.getSymbolsWithAnnotation(requireNotNull(TypewriterRegistrar::class.qualifiedName)).toList()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        if (!validateContext()) return emptyList()
        val registrars = symbols.mapNotNull(::registrar).sortedBy(Registrar::id)
        val duplicates = registrars.groupBy(Registrar::id).filterValues { it.size > 1 }
        duplicates.values.flatten().forEach { logger.error("Duplicate runtime registrar id ${it.id}.", it.declaration) }
        if (duplicates.isNotEmpty()) return emptyList()

        val bindings = registrars.flatMap { registrar -> generateProvider(registrar).bindings(registrar) }
        writeContribution(registrars, bindings)
        generated = true
        return emptyList()
    }

    private fun validateContext(): Boolean {
        val artifact = options[ARTIFACT_ID_OPTION]
        val sourcePart = options[SOURCE_PART_OPTION]
        if (artifact.isNullOrBlank()) logger.error("Missing KSP option $ARTIFACT_ID_OPTION.")
        if (sourcePart.isNullOrBlank()) logger.error("Missing KSP option $SOURCE_PART_OPTION.")
        return !artifact.isNullOrBlank() && !sourcePart.isNullOrBlank()
    }

    private fun registrar(symbol: KSAnnotated): Registrar? {
        val declaration = symbol as? KSClassDeclaration
        if (declaration == null || declaration.classKind != ClassKind.CLASS || Modifier.ABSTRACT in declaration.modifiers) {
            logger.error("Typewriter registrars must be concrete classes.", symbol)
            return null
        }
        if (Modifier.PRIVATE in declaration.modifiers || declaration.qualifiedName == null) {
            logger.error("Typewriter registrars must be visible qualified declarations.", declaration)
            return null
        }
        val runtimeRegistrarName = requireNotNull(RuntimeRegistrar::class.qualifiedName)
        if (declaration.getAllSuperTypes().none { it.declaration.qualifiedName?.asString() == runtimeRegistrarName }) {
            logger.error("Typewriter registrars must implement RuntimeRegistrar.", declaration)
            return null
        }
        val annotation = requireNotNull(declaration.annotation(requireNotNull(TypewriterRegistrar::class.qualifiedName)))
        val id = annotation.stringArgument("id").orEmpty()
        val realm = annotation.booleanArgument("realm") ?: false
        val execution = annotation.booleanArgument("execution") ?: true
        if (!id.matches(IDENTIFIER_PATTERN)) {
            logger.error("Runtime registrar ids must be safe path segments.", declaration)
            return null
        }
        if (!realm && !execution) {
            logger.error("Runtime registrars must select at least one discovery domain.", declaration)
            return null
        }
        return Registrar(id, realm, execution, declaration)
    }

    private fun generateProvider(registrar: Registrar): ClassName {
        val declaration = registrar.declaration
        val providerName = "${declaration.simpleName.asString()}DiscoveryModuleProvider"
        val providerClass = ClassName(declaration.packageName.asString(), providerName)
        val moduleBody =
            CodeBlock
                .builder()
                .add("return module {\n")
                .indent()
                .addStatement("singleOf(::%T).bind<%T>()", declaration.toClassName(), RuntimeRegistrar::class)
                .unindent()
                .add("}\n")
                .build()
        val provider =
            TypeSpec
                .classBuilder(providerName)
                .addSuperinterface(GeneratedDiscoveryModule::class)
                .addFunction(
                    FunSpec
                        .builder("module")
                        .addModifiers(KModifier.OVERRIDE)
                        .addParameter("contribution", ContributionKey::class)
                        .returns(org.koin.core.module.Module::class)
                        .addCode(moduleBody)
                        .build(),
                ).build()
        FileSpec
            .builder(declaration.packageName.asString(), providerName)
            .addImport("org.koin.core.module.dsl", "singleOf")
            .addImport("org.koin.dsl", "bind", "module")
            .addType(provider)
            .build()
            .writeTo(codeGenerator, aggregating = false, originatingKSFiles = listOfNotNull(declaration.containingFile))
        return providerClass
    }

    private fun ClassName.bindings(registrar: Registrar): List<ExecutableBinding> =
        buildList {
            if (registrar.realm) add(ExecutableBinding(registrar.id, DiscoveryDomains.Realm, canonicalName))
            if (registrar.execution) add(ExecutableBinding(registrar.id, DiscoveryDomains.Execution, canonicalName))
        }

    private fun writeContribution(
        registrars: List<Registrar>,
        bindings: List<ExecutableBinding>,
    ) {
        val files = registrars.mapNotNull { it.declaration.containingFile }.toTypedArray()
        val contribution =
            TypeDiscoveryContribution(
                definitions = emptyList(),
                prototypeBindings = emptyList(),
                executableBindings = bindings,
            )
        codeGenerator
            .createNewFileByPath(
                Dependencies(aggregating = true, *files),
                "META-INF/typewriter/contributions/types/registrars.cbor",
                "",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(contribution)) }
    }
}

private data class Registrar(
    val id: String,
    val realm: Boolean,
    val execution: Boolean,
    val declaration: KSClassDeclaration,
)

private fun KSClassDeclaration.annotation(name: String): KSAnnotation? =
    annotations.firstOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == name
    }

private fun KSAnnotation.stringArgument(name: String): String? = arguments.firstOrNull { it.name?.asString() == name }?.value as? String

private fun KSAnnotation.booleanArgument(name: String): Boolean? = arguments.firstOrNull { it.name?.asString() == name }?.value as? Boolean

private val IDENTIFIER_PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.]*")
private const val ARTIFACT_ID_OPTION = "typewriter.artifactId"
private const val SOURCE_PART_OPTION = "typewriter.sourcePart"
