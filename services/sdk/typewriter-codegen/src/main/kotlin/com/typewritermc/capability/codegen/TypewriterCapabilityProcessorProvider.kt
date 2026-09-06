package com.typewritermc.capability.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.processing.SymbolProcessor
import com.google.devtools.ksp.processing.SymbolProcessorEnvironment
import com.google.devtools.ksp.processing.SymbolProcessorProvider
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
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
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.squareup.kotlinpoet.ksp.writeTo
import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCapabilityProvider
import com.typewritermc.capability.RealmCommandCapabilityProvider
import com.typewritermc.capability.RealmCommandCapabilityRef
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmCommandOutcome
import com.typewritermc.capability.RealmComputationCapabilityProvider
import com.typewritermc.capability.RealmComputationCapabilityRef
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.capability.RealmSearch
import com.typewritermc.capability.RealmSearchCapabilityProvider
import com.typewritermc.capability.RealmSearchCapabilityRef
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchQuery
import com.typewritermc.capability.RealmSearchRequest
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ExecutableBinding
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.GeneratedDiscoveryModule
import com.typewritermc.types.DataValue
import com.typewritermc.types.TypePrototypeRegistry
import java.security.MessageDigest

/**
 * KSP entrypoint generating capability invocation bindings and discovery contributions from annotated Kotlin
 * declarations. Each compiler environment receives a fresh processor. Processing defers unresolved symbols,
 * validates supported declaration shapes, and generates its output once for the compilation. Generated resources
 * feed manifest discovery so runtime consumers do not scan source annotations.
 */
class TypewriterCapabilityProcessorProvider : SymbolProcessorProvider {
    override fun create(environment: SymbolProcessorEnvironment): SymbolProcessor =
        TypewriterCapabilityProcessor(environment.codeGenerator, environment.logger, environment.options)
}

private class TypewriterCapabilityProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val options: Map<String, String>,
) : SymbolProcessor {
    private var generated = false

    override fun process(resolver: Resolver): List<KSAnnotated> {
        if (generated) return emptyList()
        val annotations = capabilityAnnotations
        val symbols = annotations.flatMap { resolver.getSymbolsWithAnnotation(it).toList() }.distinct()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        if (deferred.isNotEmpty()) return deferred
        val artifactId = options[ARTIFACT_ID_OPTION]
        val sourcePart = options[SOURCE_PART_OPTION]
        if (artifactId.isNullOrBlank() || sourcePart.isNullOrBlank()) {
            logger.error("Realm capability generation requires Imprint artifact and source part options.")
            return emptyList()
        }
        val functions = symbols.mapNotNull(::capabilityFunction)
        if (functions.size != symbols.size) return emptyList()
        val declarations = functions.mapNotNull { capabilityDeclaration(it, artifactId, sourcePart) }
        if (declarations.size != functions.size || !validateReferenceNames(declarations)) return emptyList()
        val bindings =
            declarations
                .groupBy(CapabilityDeclaration::owner)
                .entries
                .sortedBy { it.key.qualifiedName?.asString() }
                .map { (owner, owned) -> generate(owner, owned) }
        writeContribution(bindings, functions)
        generated = true
        return emptyList()
    }

    private fun capabilityFunction(symbol: KSAnnotated): KSFunctionDeclaration? {
        val function = symbol as? KSFunctionDeclaration
        val owner = function?.parentDeclaration as? KSClassDeclaration
        if (function == null || owner == null || !owner.hasAnnotation(realmCapabilitiesName)) {
            logger.error("Realm capability functions must be members of a class annotated with RealmCapabilities.", symbol)
            return null
        }
        if (Modifier.PRIVATE in function.modifiers || function.qualifiedName == null) {
            logger.error("Realm capability functions must be visible and qualified.", function)
            return null
        }
        if (Modifier.PRIVATE in owner.modifiers || owner.qualifiedName == null) {
            logger.error("Realm capability classes must be visible and qualified.", owner)
            return null
        }
        if (function.parameters.size != 1) {
            logger.error("Realm capability functions require exactly one value parameter.", function)
            return null
        }
        if (function.annotations.count { it.qualifiedName() in capabilityAnnotations } != 1) {
            logger.error("Realm capability functions require exactly one capability annotation.", function)
            return null
        }

        /*
         * TODO: Replace this temporary capability class requirement with top level
         * capability functions once KSP exposes context parameters.
         *
         * Target:
         *
         * context(
         *     runtime: RealmSearchContext,
         *     players: PlayerRepository,
         * )
         * @RealmCapability.Search
         * fun searchPlayers(
         *     request: RealmSearchRequest<PlayerFilter>,
         * ): RealmSearch<PlayerOption> = realmSearch {
         *     partial(players.search(request.query))
         *     complete()
         * }
         *
         * Remove RealmCapabilities, generated handler construction, and constructor
         * dependency injection during this migration.
         *
         * Track: https://github.com/google/ksp/issues/2472
         */
        return function
    }

    private fun capabilityDeclaration(
        function: KSFunctionDeclaration,
        artifactId: String,
        sourcePart: String,
    ): CapabilityDeclaration? {
        val kind = CapabilityKind.entries.single { function.hasAnnotation(it.annotationName) }
        val parameterType =
            function.parameters
                .single()
                .type
                .resolve()
        val returnType = function.returnType?.resolve()
        val requestType: KSType
        val resultType: KSType?
        when (kind) {
            CapabilityKind.SEARCH -> {
                requestType = parameterType.singleTypeArgument(RealmSearchRequest::class.qualifiedName, function) ?: return null
                resultType = returnType?.singleTypeArgument(RealmSearch::class.qualifiedName, function) ?: return null
            }

            CapabilityKind.COMPUTATION -> {
                if (Modifier.SUSPEND !in function.modifiers) {
                    logger.error("Realm computation functions must be suspend functions.", function)
                    return null
                }
                requestType = parameterType
                resultType = returnType ?: return null
            }

            CapabilityKind.COMMAND -> {
                if (Modifier.SUSPEND !in function.modifiers) {
                    logger.error("Realm command functions must be suspend functions.", function)
                    return null
                }
                if (returnType?.declaration?.qualifiedName?.asString() != RealmCommandOutcome::class.qualifiedName) {
                    logger.error("Realm command functions must return RealmCommandOutcome.", function)
                    return null
                }
                requestType = parameterType
                resultType = null
            }
        }
        val owner = function.parentDeclaration as KSClassDeclaration
        val signature =
            listOf(
                artifactId,
                sourcePart,
                function.packageName.asString(),
                owner.qualifiedName?.asString(),
                function.simpleName.asString(),
                kind.name,
                requestType.canonicalName(),
                resultType?.canonicalName(),
            ).joinToString("|")
        return CapabilityDeclaration(
            owner = owner,
            function = function,
            kind = kind,
            requestType = requestType.toTypeName(),
            resultType = resultType?.toTypeName(),
            id = "cap_v1_${signature.sha256()}",
        )
    }

    private fun validateReferenceNames(declarations: List<CapabilityDeclaration>): Boolean {
        val duplicates = declarations.groupBy { it.function.packageName.asString() to it.referenceName }.filterValues { it.size > 1 }
        duplicates.values.flatten().forEach { declaration ->
            logger.error("Generated capability reference ${declaration.referenceName} is not unique in its package.", declaration.function)
        }
        return duplicates.isEmpty()
    }

    private fun generate(
        owner: KSClassDeclaration,
        declarations: List<CapabilityDeclaration>,
    ): ExecutableBinding {
        val packageName = owner.packageName.asString()
        val ownerType = ClassName.bestGuess(requireNotNull(owner.qualifiedName).asString())
        val ownerName = owner.simpleName.asString()
        val moduleName = "${ownerName}RealmCapabilityDiscoveryModule"
        val moduleClass = ClassName(packageName, moduleName)
        val file = FileSpec.builder(packageName, moduleName)
        declarations.sortedBy(CapabilityDeclaration::referenceName).forEach { declaration ->
            file.addProperty(declaration.referenceProperty())
            file.addType(declaration.providerType(ownerType))
        }
        file.addType(discoveryModule(moduleName, ownerType, declarations))
        file
            .addImport("kotlin", "context")
            .addImport("org.koin.core.module.dsl", "bind", "named", "singleOf")
            .addImport("org.koin.dsl", "module")
            .addImport("com.typewritermc.capability", "decodeCapabilityValue", "encodeCapabilityValue", "mapValues")
            .build()
            .writeTo(codeGenerator, aggregating = false, originatingKSFiles = listOfNotNull(owner.containingFile))
        return ExecutableBinding("capability.${moduleClass.canonicalName}", DiscoveryDomains.Realm, moduleClass.canonicalName)
    }

    private fun discoveryModule(
        moduleName: String,
        ownerType: ClassName,
        declarations: List<CapabilityDeclaration>,
    ): TypeSpec =
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
                            .apply {
                                add("return module {\n")
                                indent()
                                add("singleOf(::%T)\n", ownerType)
                                declarations.sortedBy(CapabilityDeclaration::providerName).forEach { declaration ->
                                    add("singleOf(::%T) {\n", ClassName(ownerType.packageName, declaration.providerName))
                                    indent()
                                    add("named(%S)\n", "capability.${declaration.id}")
                                    add("bind<%T>()\n", RealmCapabilityProvider::class)
                                    unindent()
                                    add("}\n")
                                }
                                unindent()
                                add("}\n")
                            }.build(),
                    ).build(),
            ).build()

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
                "realm_capabilities",
                "cbor",
            ).use { it.write(TypeDiscoveryContributionCodec.encode(contribution)) }
    }
}

private data class CapabilityDeclaration(
    val owner: KSClassDeclaration,
    val function: KSFunctionDeclaration,
    val kind: CapabilityKind,
    val requestType: TypeName,
    val resultType: TypeName?,
    val id: String,
) {
    val referenceName: String = "${function.simpleName.asString()}Capability"
    val providerName: String =
        "${owner.simpleName.asString()}${function.simpleName.asString().replaceFirstChar(Char::uppercase)}CapabilityProvider"

    fun referenceProperty(): PropertySpec {
        val type =
            when (kind) {
                CapabilityKind.SEARCH -> {
                    RealmSearchCapabilityRef::class.asClassName().parameterizedBy(requestType, requireNotNull(resultType))
                }

                CapabilityKind.COMPUTATION -> {
                    RealmComputationCapabilityRef::class.asClassName().parameterizedBy(requestType, requireNotNull(resultType))
                }

                CapabilityKind.COMMAND -> {
                    RealmCommandCapabilityRef::class.asClassName().parameterizedBy(requestType)
                }
            }
        val constructor =
            when (kind) {
                CapabilityKind.SEARCH -> RealmSearchCapabilityRef::class
                CapabilityKind.COMPUTATION -> RealmComputationCapabilityRef::class
                CapabilityKind.COMMAND -> RealmCommandCapabilityRef::class
            }
        return PropertySpec
            .builder(referenceName, type)
            .initializer(
                when (kind) {
                    CapabilityKind.SEARCH,
                    CapabilityKind.COMPUTATION,
                    -> "%T(%T(%S), %T::class, %T::class)"

                    CapabilityKind.COMMAND -> "%T(%T(%S), %T::class)"
                },
                constructor,
                CapabilityId::class,
                id,
                requestType,
                *listOfNotNull(resultType).toTypedArray(),
            ).build()
    }

    fun providerType(ownerType: ClassName): TypeSpec {
        val providerInterface =
            when (kind) {
                CapabilityKind.SEARCH -> RealmSearchCapabilityProvider::class
                CapabilityKind.COMPUTATION -> RealmComputationCapabilityProvider::class
                CapabilityKind.COMMAND -> RealmCommandCapabilityProvider::class
            }
        return TypeSpec
            .classBuilder(providerName)
            .addModifiers(KModifier.INTERNAL)
            .primaryConstructor(FunSpec.constructorBuilder().addParameter("handler", ownerType).build())
            .addProperty(PropertySpec.builder("handler", ownerType, KModifier.PRIVATE).initializer("handler").build())
            .addSuperinterface(providerInterface)
            .addProperty(
                PropertySpec.builder("id", CapabilityId::class, KModifier.OVERRIDE).initializer("%N.id", referenceName).build(),
            ).addFunction(descriptorFunction())
            .addFunction(invokeFunction())
            .build()
    }

    private fun descriptorFunction(): FunSpec {
        val descriptorType =
            when (kind) {
                CapabilityKind.SEARCH -> RealmCapabilityDescriptor.Search::class
                CapabilityKind.COMPUTATION -> RealmCapabilityDescriptor.Computation::class
                CapabilityKind.COMMAND -> RealmCapabilityDescriptor.Command::class
            }
        return FunSpec
            .builder("descriptor")
            .addModifiers(KModifier.OVERRIDE)
            .addParameter("prototypes", TypePrototypeRegistry::class)
            .returns(RealmCapabilityDescriptor::class)
            .addStatement(
                when (kind) {
                    CapabilityKind.SEARCH,
                    CapabilityKind.COMPUTATION,
                    -> "return %T(id, prototypes.require(%T::class).type, prototypes.require(%T::class).type)"

                    CapabilityKind.COMMAND -> "return %T(id, prototypes.require(%T::class).type)"
                },
                descriptorType,
                requestType,
                *listOfNotNull(resultType).toTypedArray(),
            ).build()
    }

    private fun invokeFunction(): FunSpec {
        val builder = FunSpec.builder("invoke").addModifiers(KModifier.OVERRIDE)
        when (kind) {
            CapabilityKind.SEARCH -> {
                builder
                    .addParameter("context", RealmSearchContext::class)
                    .addParameter("prototypes", TypePrototypeRegistry::class)
                    .addParameter("payload", DataValue::class)
                    .addParameter("query", RealmSearchQuery::class)
                    .returns(com.typewritermc.capability.RealmSearch::class.asClassName().parameterizedBy(DataValue::class.asClassName()))
                    .addStatement("val decoded = prototypes.decodeCapabilityValue(%T::class, payload)", requestType)
                    .addStatement("val request = %T(decoded, query)", RealmSearchRequest::class)
                    .addStatement(
                        "return with(context) { handler.%N(request) }.mapValues { prototypes.encodeCapabilityValue(%T::class, it) }",
                        function.simpleName.asString(),
                        requireNotNull(resultType),
                    )
            }

            CapabilityKind.COMPUTATION -> {
                builder
                    .addModifiers(KModifier.SUSPEND)
                    .addParameter("context", RealmComputationContext::class)
                    .addParameter("prototypes", TypePrototypeRegistry::class)
                    .addParameter("payload", DataValue::class)
                    .returns(DataValue::class)
                    .addStatement("val decoded = prototypes.decodeCapabilityValue(%T::class, payload)", requestType)
                    .addStatement(
                        "val result = with(context) { handler.%N(decoded) }",
                        function.simpleName.asString(),
                    ).addStatement("return prototypes.encodeCapabilityValue(%T::class, result)", requireNotNull(resultType))
            }

            CapabilityKind.COMMAND -> {
                builder
                    .addModifiers(KModifier.SUSPEND)
                    .addParameter("context", RealmCommandContext::class)
                    .addParameter("prototypes", TypePrototypeRegistry::class)
                    .addParameter("payload", DataValue::class)
                    .returns(RealmCommandOutcome::class)
                    .addStatement("val decoded = prototypes.decodeCapabilityValue(%T::class, payload)", requestType)
                    .addStatement("return with(context) { handler.%N(decoded) }", function.simpleName.asString())
            }
        }
        return builder.build()
    }
}

private enum class CapabilityKind(
    val annotationName: String,
) {
    SEARCH(requireNotNull(RealmCapability.Search::class.qualifiedName)),
    COMPUTATION(requireNotNull(RealmCapability.Computation::class.qualifiedName)),
    COMMAND(requireNotNull(RealmCapability.Command::class.qualifiedName)),
}

private fun KSType.singleTypeArgument(
    expectedDeclaration: String?,
    symbol: KSAnnotated,
): KSType? {
    if (declaration.qualifiedName?.asString() != expectedDeclaration || arguments.size != 1) return null
    return arguments.single().type?.resolve().also {
        if (it == null) error("Realm capability generic arguments must be concrete at $symbol.")
    }
}

private fun KSType.canonicalName(): String =
    buildString {
        append(declaration.qualifiedName?.asString() ?: declaration.simpleName.asString())
        if (arguments.isNotEmpty()) {
            append(arguments.joinToString(prefix = "<", postfix = ">") { it.type?.resolve()?.canonicalName() ?: "*" })
        }
        if (isMarkedNullable) append("?")
    }

private fun KSAnnotated.hasAnnotation(qualifiedName: String): Boolean = annotations.any { it.qualifiedName() == qualifiedName }

private fun KSAnnotation.qualifiedName(): String? =
    annotationType
        .resolve()
        .declaration.qualifiedName
        ?.asString()

private fun String.sha256(): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest(toByteArray())
        .joinToString("") { "%02x".format(it) }

private val capabilityAnnotations = CapabilityKind.entries.map(CapabilityKind::annotationName)
private val realmCapabilitiesName = requireNotNull(RealmCapabilities::class.qualifiedName)
private const val ARTIFACT_ID_OPTION = "typewriter.artifactId"
private const val SOURCE_PART_OPTION = "typewriter.sourcePart"
