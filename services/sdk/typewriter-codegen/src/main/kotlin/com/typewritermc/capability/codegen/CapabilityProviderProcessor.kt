package com.typewritermc.capability.codegen

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.squareup.kotlinpoet.FunSpec
import com.squareup.kotlinpoet.KModifier
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.PropertySpec
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.TypeSpec
import com.squareup.kotlinpoet.asClassName
import com.squareup.kotlinpoet.ksp.toClassName
import com.squareup.kotlinpoet.ksp.toTypeName
import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilities
import com.typewritermc.capability.RealmCapability
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.codegen.DefinitionReferences
import com.typewritermc.codegen.GeneratedFile
import com.typewritermc.codegen.GeneratedOutput
import com.typewritermc.codegen.getSymbolsWithAnnotation
import com.typewritermc.codegen.isType
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.rawAnnotation
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.TypeUse
import com.typewritermc.types.codegen.DefinitionOwners
import com.typewritermc.types.codegen.referencedIds
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.KspTypeGraphConverter
import skirout.editor.v1.search.RealmSearchQuery
import java.security.MessageDigest
import kotlin.reflect.KClass
import com.typewritermc.codegen.TypewriterApi as Api

/**
 * Emits a capability reference and a provider factory for each realm capability function.
 *
 * The capability id hashes the source part, owner, function, kind and portable signature, so it changes whenever the
 * contract a client depends on changes.
 */
internal class CapabilityProviderProcessor(
    private val output: GeneratedOutput,
    private val owners: DefinitionOwners,
    private val logger: KSPLogger,
    private val sourcePart: String,
) {
    /** Processes this round's capability functions and returns the symbols to defer. */
    fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = CapabilityKind.entries.flatMap { resolver.getSymbolsWithAnnotation(it.annotation).toList() }.distinct()
        context(resolver) { symbols.filter(KSAnnotated::validate).forEach { provide(it) } }
        return symbols.filterNot(KSAnnotated::validate)
    }

    context(_: Resolver)
    private fun provide(symbol: KSAnnotated) {
        val function = symbol as? KSFunctionDeclaration
        val owner = function?.parentDeclaration as? KSClassDeclaration
        if (function == null || owner == null || owner.rawAnnotation(RealmCapabilities::class) == null) {
            logger.error("Realm capability functions must belong to a RealmCapabilities class.", symbol)
            return
        }
        if (Modifier.PRIVATE in function.modifiers || Modifier.PRIVATE in owner.modifiers) {
            logger.error("Realm capability functions and owners must be visible.", function)
            return
        }
        if (function.parameters.size != 1) {
            logger.error("Realm capability functions require one value parameter.", function)
            return
        }
        val kind = CapabilityKind.entries.singleOrNull { function.rawAnnotation(it.annotation) != null }
        if (kind == null) {
            logger.error("Realm capability functions require one capability annotation.", function)
            return
        }
        val declaration = declaration(owner, function, kind) ?: return
        output.provide(declaration.file(), declaration.factory, GeneratedProviderKind.Capability, function)
    }

    context(_: Resolver)
    private fun declaration(
        owner: KSClassDeclaration,
        function: KSFunctionDeclaration,
        kind: CapabilityKind,
    ): CapabilityDeclaration? {
        val parameter =
            function.parameters
                .single()
                .type
                .resolve()
        val result = function.returnType?.resolve()
        val requestType: KSType
        val resultType: KSType?
        when (kind) {
            CapabilityKind.Search -> {
                requestType = parameter.singleArgument(Api.RealmSearchRequest, function) ?: return null
                resultType = result?.singleArgument(Api.RealmSearch, function) ?: return null
            }

            CapabilityKind.Computation -> {
                if (Modifier.SUSPEND !in function.modifiers) {
                    logger.error("Realm computation capabilities must be suspend functions.", function)
                    return null
                }
                requestType = parameter
                resultType = result ?: return null
            }

            CapabilityKind.Command -> {
                if (Modifier.SUSPEND !in function.modifiers || result?.declaration?.isType(Api.RealmCommandOutcome) != true) {
                    logger.error("Realm command capabilities must be suspend functions returning RealmCommandOutcome.", function)
                    return null
                }
                requestType = parameter
                resultType = null
            }
        }
        val request = requestType.completeUse(function) ?: return null
        val resultUse = resultType?.let { it.completeUse(function) ?: return null }
        val ownerClass = owner.toClassName()
        val functionName = function.simpleName.asString()
        val suffix = functionName.replaceFirstChar(Char::uppercase)
        val identity =
            listOf(sourcePart, ownerClass.canonicalName, functionName, kind.name, request.use, resultUse?.use).joinToString("|")
        val references =
            owners.references(
                request.conversion.declarations + resultUse?.conversion?.declarations.orEmpty(),
                request.use.referencedIds() + resultUse?.use?.referencedIds().orEmpty(),
                function,
            ) ?: return null
        return CapabilityDeclaration(
            owner = ownerClass,
            functionName = functionName,
            factory = ClassName(ownerClass.packageName, "${owner.simpleName.asString()}${suffix}GeneratedCapabilityProvider"),
            provider = ClassName(ownerClass.packageName, "${owner.simpleName.asString()}${suffix}BoundCapabilityProvider"),
            kind = kind,
            id = "cap_${identity.sha256()}",
            requestType = requestType.toTypeName(),
            resultType = resultType?.toTypeName(),
            requestUse = request.use,
            resultUse = resultUse?.use,
            references = references,
        )
    }

    private fun KSType.completeUse(source: KSAnnotated): ConvertedUse? =
        when (val converted = KspTypeGraphConverter().convert(this)) {
            is KspTypeConversionResult.Success -> {
                ConvertedUse(converted.root, converted)
            }

            is KspTypeConversionResult.Failure -> {
                converted.diagnostics.forEach { diagnostic -> logger.error(diagnostic.toString(), source) }
                null
            }
        }

    private fun KSType.singleArgument(
        expected: ClassName,
        source: KSAnnotated,
    ): KSType? {
        if (!(declaration isType expected) || arguments.size != 1) {
            logger.error("Realm capability type must be ${expected.canonicalName} with one concrete argument.", source)
            return null
        }
        return arguments.single().type?.resolve()?.takeUnless(KSType::isError).also {
            if (it == null) logger.error("Realm capability type arguments must resolve.", source)
        }
    }
}

private class ConvertedUse(
    val use: TypeUse,
    val conversion: KspTypeConversionResult.Success,
)

private class CapabilityDeclaration(
    val owner: ClassName,
    val functionName: String,
    val factory: ClassName,
    val provider: ClassName,
    val kind: CapabilityKind,
    val id: String,
    val requestType: TypeName,
    val resultType: TypeName?,
    val requestUse: TypeUse,
    val resultUse: TypeUse?,
    val references: DefinitionReferences,
) {
    private val descriptorType: ClassName = kind.descriptor.asClassName()

    fun file() =
        GeneratedFile
            .builder(factory.packageName, factory.simpleName)
            .addProperty(reference())
            .addType(factoryType())
            .addType(providerType())
            .build()

    /** `val <function>Capability`: the typed reference clients invoke the capability through. */
    private fun reference(): PropertySpec {
        val referenceId = CodeBlock.of("%T(%S)", CapabilityId::class, id)
        val (type, value) =
            when (kind) {
                CapabilityKind.Search -> {
                    Api.RealmSearchCapabilityRef.parameterizedBy(requestType, resultType!!) to
                        CodeBlock.of("%T(%L,♢%T::class,♢%T::class)", Api.RealmSearchCapabilityRef, referenceId, requestType, resultType)
                }

                CapabilityKind.Computation -> {
                    Api.RealmComputationCapabilityRef.parameterizedBy(requestType, resultType!!) to
                        CodeBlock.of(
                            "%T(%L,♢%T::class,♢%T::class)",
                            Api.RealmComputationCapabilityRef,
                            referenceId,
                            requestType,
                            resultType,
                        )
                }

                CapabilityKind.Command -> {
                    Api.RealmCommandCapabilityRef.parameterizedBy(requestType) to
                        CodeBlock.of("%T(%L,♢%T::class)", Api.RealmCommandCapabilityRef, referenceId, requestType)
                }
            }
        return PropertySpec.builder("${functionName}Capability", type).initializer(value).build()
    }

    private fun factoryType(): TypeSpec {
        val descriptor =
            context(references) {
                when (kind) {
                    CapabilityKind.Search, CapabilityKind.Computation -> {
                        CodeBlock.of("%T(id,♢%L,♢%L)", descriptorType, requestUse.kotlinCode(), requireNotNull(resultUse).kotlinCode())
                    }

                    CapabilityKind.Command -> {
                        CodeBlock.of("%T(id,♢%L)", descriptorType, requestUse.kotlinCode())
                    }
                }
            }
        return TypeSpec
            .classBuilder(factory)
            .addSuperinterface(Api.GeneratedCapabilityProvider)
            .addProperty(
                PropertySpec
                    .builder("id", CapabilityId::class, KModifier.PRIVATE)
                    .initializer("%T(%S)", CapabilityId::class, id)
                    .build(),
            ).addProperty(PropertySpec.builder("descriptor", descriptorType, KModifier.OVERRIDE).initializer(descriptor).build())
            .addFunction(
                FunSpec
                    .builder("bind")
                    .addModifiers(KModifier.OVERRIDE)
                    .addParameter("resolver", Api.CapabilityOwnerResolver)
                    .returns(Api.RealmCapabilityProvider)
                    .addStatement("return %T(resolver.resolve(%T::class) as %T,♢descriptor)", provider, owner, owner)
                    .build(),
            ).build()
    }

    private fun providerType(): TypeSpec {
        val dataValue = DataValue::class.asClassName()
        val invoke =
            when (kind) {
                CapabilityKind.Search -> {
                    FunSpec
                        .builder("invoke")
                        .addParameter("context", Api.RealmSearchContext)
                        .addParameter("runtime", Api.RealmCapabilityRuntime)
                        .addParameter("payload", dataValue)
                        .addParameter("query", RealmSearchQuery::class)
                        .returns(Api.RealmSearch.parameterizedBy(dataValue))
                        .addStatement("val decoded = runtime.decode<%T>(descriptor.requestType,♢payload)", requestType)
                        .addStatement(
                            "return with(context) { handler.%N(%T(decoded,♢query)) }.%M { runtime.encode(descriptor.resultType,♢it) }",
                            functionName,
                            Api.RealmSearchRequest,
                            Api.mapValues,
                        )
                }

                CapabilityKind.Computation -> {
                    FunSpec
                        .builder("invoke")
                        .addModifiers(KModifier.SUSPEND)
                        .addParameter("context", Api.RealmComputationContext)
                        .addParameter("runtime", Api.RealmCapabilityRuntime)
                        .addParameter("payload", dataValue)
                        .returns(dataValue)
                        .addStatement("val decoded = runtime.decode<%T>(descriptor.requestType,♢payload)", requestType)
                        .addStatement("val result = with(context) { handler.%N(decoded) }", functionName)
                        .addStatement("return runtime.encode(descriptor.resultType, result)")
                }

                CapabilityKind.Command -> {
                    FunSpec
                        .builder("invoke")
                        .addModifiers(KModifier.SUSPEND)
                        .addParameter("context", Api.RealmCommandContext)
                        .addParameter("runtime", Api.RealmCapabilityRuntime)
                        .addParameter("payload", dataValue)
                        .returns(Api.RealmCommandOutcome)
                        .addStatement("val decoded = runtime.decode<%T>(descriptor.requestType,♢payload)", requestType)
                        .addStatement("return with(context) { handler.%N(decoded) }", functionName)
                }
            }
        return TypeSpec
            .classBuilder(provider)
            .addModifiers(KModifier.PRIVATE)
            .primaryConstructor(
                FunSpec
                    .constructorBuilder()
                    .addParameter("handler", owner)
                    .addParameter("descriptor", descriptorType)
                    .build(),
            ).addProperty(PropertySpec.builder("handler", owner, KModifier.PRIVATE).initializer("handler").build())
            .addProperty(PropertySpec.builder("descriptor", descriptorType, KModifier.OVERRIDE).initializer("descriptor").build())
            .addSuperinterface(kind.provider)
            .addFunction(invoke.addModifiers(KModifier.OVERRIDE).build())
            .build()
    }
}

private enum class CapabilityKind(
    val annotation: KClass<out Annotation>,
    val descriptor: KClass<out RealmCapabilityDescriptor>,
    val provider: ClassName,
) {
    Search(RealmCapability.Search::class, RealmCapabilityDescriptor.Search::class, Api.RealmSearchCapabilityProvider),
    Computation(RealmCapability.Computation::class, RealmCapabilityDescriptor.Computation::class, Api.RealmComputationCapabilityProvider),
    Command(RealmCapability.Command::class, RealmCapabilityDescriptor.Command::class, Api.RealmCommandCapabilityProvider),
}

private fun String.sha256(): String = MessageDigest.getInstance("SHA-256").digest(encodeToByteArray()).toHexString()
