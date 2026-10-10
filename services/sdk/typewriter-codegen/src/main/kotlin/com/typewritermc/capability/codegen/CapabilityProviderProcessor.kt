package com.typewritermc.capability.codegen

import com.google.devtools.ksp.processing.CodeGenerator
import com.google.devtools.ksp.processing.Dependencies
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.Modifier
import com.google.devtools.ksp.validate
import com.squareup.kotlinpoet.ksp.toTypeName
import com.typewritermc.codegen.GeneratedProviderContribution
import com.typewritermc.codegen.ProviderProcessingResult
import com.typewritermc.codegen.kotlinCode
import com.typewritermc.codegen.kotlinLiteral
import com.typewritermc.types.TypeUse
import com.typewritermc.types.ksp.KspTypeConversionResult
import com.typewritermc.types.ksp.KspTypeGraphConverter
import java.security.MessageDigest

class CapabilityProviderProcessor(
    private val codeGenerator: CodeGenerator,
    private val logger: KSPLogger,
    private val sourcePart: String,
) {
    private val generated = mutableSetOf<String>()

    fun process(resolver: Resolver): ProviderProcessingResult {
        val symbols = CAPABILITY_ANNOTATIONS.flatMap { resolver.getSymbolsWithAnnotation(it).toList() }.distinct()
        val deferred = symbols.filterNot(KSAnnotated::validate)
        val providers =
            symbols.filter(KSAnnotated::validate).mapNotNull { symbol ->
                val function = symbol as? KSFunctionDeclaration
                val owner = function?.parentDeclaration as? KSClassDeclaration
                if (function == null || owner == null || !owner.hasAnnotation(REALM_CAPABILITIES)) {
                    logger.error("Realm capability functions must belong to a RealmCapabilities class.", symbol)
                    return@mapNotNull null
                }
                if (Modifier.PRIVATE in function.modifiers || Modifier.PRIVATE in owner.modifiers) {
                    logger.error("Realm capability functions and owners must be visible.", function)
                    return@mapNotNull null
                }
                if (function.parameters.size != 1) {
                    logger.error("Realm capability functions require one value parameter.", function)
                    return@mapNotNull null
                }
                val kind = CapabilityKind.entries.singleOrNull { function.hasAnnotation(it.annotation) }
                if (kind == null) {
                    logger.error("Realm capability functions require one capability annotation.", function)
                    return@mapNotNull null
                }
                val declaration = declaration(owner, function, kind) ?: return@mapNotNull null
                if (!generated.add(declaration.providerClass)) return@mapNotNull null
                write(declaration)
                GeneratedProviderContribution("capability", declaration.providerClass)
            }
        return ProviderProcessingResult(providers, deferred)
    }

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
                requestType = parameter.singleArgument(REALM_SEARCH_REQUEST, function) ?: return null
                resultType = result?.singleArgument(REALM_SEARCH, function) ?: return null
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
                if (Modifier.SUSPEND !in function.modifiers || result?.declaration?.qualifiedName?.asString() != REALM_COMMAND_OUTCOME) {
                    logger.error("Realm command capabilities must be suspend functions returning RealmCommandOutcome.", function)
                    return null
                }
                requestType = parameter
                resultType = null
            }
        }
        val requestUse = requestType.completeUse(function) ?: return null
        val resultUse = resultType?.completeUse(function)
        if (resultType != null && resultUse == null) return null
        val packageName = owner.packageName.asString()
        val ownerName = requireNotNull(owner.qualifiedName).asString()
        val functionName = function.simpleName.asString()
        val suffix = functionName.replaceFirstChar(Char::uppercase)
        val factoryName = "${owner.simpleName.asString()}${suffix}GeneratedCapabilityProvider"
        val providerName = "${owner.simpleName.asString()}${suffix}BoundCapabilityProvider"
        val identity = listOf(sourcePart, ownerName, functionName, kind.name, requestUse, resultUse).joinToString("|")
        return CapabilityDeclaration(
            packageName = packageName,
            ownerName = ownerName,
            functionName = functionName,
            factoryName = factoryName,
            providerName = providerName,
            providerClass = "$packageName.$factoryName",
            kind = kind,
            id = "cap_${identity.sha256()}",
            requestKotlinType = requestType.toTypeName().toString(),
            resultKotlinType = resultType?.toTypeName()?.toString(),
            requestUse = requestUse,
            resultUse = resultUse,
            source = function,
        )
    }

    private fun write(declaration: CapabilityDeclaration) {
        codeGenerator
            .createNewFile(
                Dependencies(false, *listOfNotNull(declaration.source.containingFile).toTypedArray()),
                declaration.packageName,
                declaration.factoryName,
            ).bufferedWriter()
            .use { it.write(declaration.sourceCode()) }
    }

    private fun KSType.completeUse(source: KSAnnotated): TypeUse? =
        when (val converted = KspTypeGraphConverter().convert(this)) {
            is KspTypeConversionResult.Success -> {
                converted.root
            }

            is KspTypeConversionResult.Failure -> {
                converted.diagnostics.forEach { diagnostic -> logger.error(diagnostic.toString(), source) }
                null
            }
        }

    private fun KSType.singleArgument(
        expected: String,
        source: KSAnnotated,
    ): KSType? {
        if (declaration.qualifiedName?.asString() != expected || arguments.size != 1) {
            logger.error("Realm capability type must be $expected with one concrete argument.", source)
            return null
        }
        return arguments.single().type?.resolve()?.takeUnless(KSType::isError).also {
            if (it == null) logger.error("Realm capability type arguments must resolve.", source)
        }
    }
}

private data class CapabilityDeclaration(
    val packageName: String,
    val ownerName: String,
    val functionName: String,
    val factoryName: String,
    val providerName: String,
    val providerClass: String,
    val kind: CapabilityKind,
    val id: String,
    val requestKotlinType: String,
    val resultKotlinType: String?,
    val requestUse: TypeUse,
    val resultUse: TypeUse?,
    val source: KSFunctionDeclaration,
) {
    fun sourceCode(): String {
        val requestUseCode = requestUse.kotlinCode()
        val resultUseCode = resultUse?.kotlinCode()
        val descriptor =
            when (kind) {
                CapabilityKind.Search -> {
                    "com.typewritermc.capability.RealmCapabilityDescriptor.Search(" +
                        "id, $requestUseCode, ${requireNotNull(resultUseCode)})"
                }

                CapabilityKind.Computation -> {
                    "com.typewritermc.capability.RealmCapabilityDescriptor.Computation(" +
                        "id, $requestUseCode, ${requireNotNull(resultUseCode)})"
                }

                CapabilityKind.Command -> {
                    "com.typewritermc.capability.RealmCapabilityDescriptor.Command(id, $requestUseCode)"
                }
            }
        val resultType = resultKotlinType
        val referenceType =
            when (kind) {
                CapabilityKind.Search -> {
                    "com.typewritermc.capability.RealmSearchCapabilityRef<" +
                        "$requestKotlinType, ${requireNotNull(resultType)}>"
                }

                CapabilityKind.Computation -> {
                    "com.typewritermc.capability.RealmComputationCapabilityRef<" +
                        "$requestKotlinType, ${requireNotNull(resultType)}>"
                }

                CapabilityKind.Command -> {
                    "com.typewritermc.capability.RealmCommandCapabilityRef<$requestKotlinType>"
                }
            }
        val referenceId = "com.typewritermc.capability.CapabilityId(${id.kotlinLiteral()})"
        val referenceValue =
            when (kind) {
                CapabilityKind.Search -> {
                    "com.typewritermc.capability.RealmSearchCapabilityRef(" +
                        "$referenceId, $requestKotlinType::class, ${requireNotNull(resultType)}::class)"
                }

                CapabilityKind.Computation -> {
                    "com.typewritermc.capability.RealmComputationCapabilityRef(" +
                        "$referenceId, $requestKotlinType::class, ${requireNotNull(resultType)}::class)"
                }

                CapabilityKind.Command -> {
                    "com.typewritermc.capability.RealmCommandCapabilityRef($referenceId, $requestKotlinType::class)"
                }
            }
        val providerInterface =
            when (kind) {
                CapabilityKind.Search -> "com.typewritermc.capability.RealmSearchCapabilityProvider"
                CapabilityKind.Computation -> "com.typewritermc.capability.RealmComputationCapabilityProvider"
                CapabilityKind.Command -> "com.typewritermc.capability.RealmCommandCapabilityProvider"
            }
        val invocation =
            when (kind) {
                CapabilityKind.Search -> {
                    """
    override fun invoke(
        context: com.typewritermc.capability.RealmSearchContext,
        runtime: com.typewritermc.capability.RealmCapabilityRuntime,
        payload: com.typewritermc.types.DataValue,
        query: com.typewritermc.capability.RealmSearchQuery,
    ): com.typewritermc.capability.RealmSearch<com.typewritermc.types.DataValue> {
        val decoded = runtime.decode<$requestKotlinType>(descriptor.requestType, payload)
        return with(context) { handler.$functionName(com.typewritermc.capability.RealmSearchRequest(decoded, query)) }
            .mapValues { runtime.encode((descriptor as com.typewritermc.capability.RealmCapabilityDescriptor.Search).resultType, it) }
    }
"""
                }

                CapabilityKind.Computation -> {
                    """
    override suspend fun invoke(
        context: com.typewritermc.capability.RealmComputationContext,
        runtime: com.typewritermc.capability.RealmCapabilityRuntime,
        payload: com.typewritermc.types.DataValue,
    ): com.typewritermc.types.DataValue {
        val decoded = runtime.decode<$requestKotlinType>(descriptor.requestType, payload)
        val result = with(context) { handler.$functionName(decoded) }
        return runtime.encode((descriptor as com.typewritermc.capability.RealmCapabilityDescriptor.Computation).resultType, result)
    }
"""
                }

                CapabilityKind.Command -> {
                    """
    override suspend fun invoke(
        context: com.typewritermc.capability.RealmCommandContext,
        runtime: com.typewritermc.capability.RealmCapabilityRuntime,
        payload: com.typewritermc.types.DataValue,
    ): com.typewritermc.capability.RealmCommandOutcome {
        val decoded = runtime.decode<$requestKotlinType>(descriptor.requestType, payload)
        return with(context) { handler.$functionName(decoded) }
    }
"""
                }
            }
        return """
package $packageName

import com.typewritermc.capability.mapValues

val ${functionName}Capability: $referenceType = $referenceValue

class $factoryName : com.typewritermc.discovery.GeneratedCapabilityProvider {
    private val id = com.typewritermc.capability.CapabilityId(${id.kotlinLiteral()})
    override val descriptor: com.typewritermc.capability.RealmCapabilityDescriptor = $descriptor

    override fun bind(
        resolver: com.typewritermc.discovery.CapabilityOwnerResolver,
    ): com.typewritermc.capability.RealmCapabilityProvider =
        $providerName(resolver.resolve($ownerName::class) as $ownerName, descriptor)
}

private class $providerName(
    private val handler: $ownerName,
    override val descriptor: com.typewritermc.capability.RealmCapabilityDescriptor,
) : $providerInterface {
$invocation
}
""".trimStart()
    }
}

private enum class CapabilityKind(
    val annotation: String,
) {
    Search(REALM_SEARCH_ANNOTATION),
    Computation(REALM_COMPUTATION_ANNOTATION),
    Command(REALM_COMMAND_ANNOTATION),
}

private fun KSAnnotated.hasAnnotation(qualifiedName: String): Boolean =
    annotations.any { annotation ->
        annotation.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(encodeToByteArray()).joinToString("") { byte ->
        "%02x".format(byte.toInt() and 0xff)
    }

private val CAPABILITY_ANNOTATIONS = listOf(REALM_SEARCH_ANNOTATION, REALM_COMPUTATION_ANNOTATION, REALM_COMMAND_ANNOTATION)
private const val REALM_CAPABILITIES = "com.typewritermc.capability.RealmCapabilities"
private const val REALM_SEARCH_ANNOTATION = "com.typewritermc.capability.RealmCapability.Search"
private const val REALM_COMPUTATION_ANNOTATION = "com.typewritermc.capability.RealmCapability.Computation"
private const val REALM_COMMAND_ANNOTATION = "com.typewritermc.capability.RealmCapability.Command"
private const val REALM_SEARCH_REQUEST = "com.typewritermc.capability.RealmSearchRequest"
private const val REALM_SEARCH = "com.typewritermc.capability.RealmSearch"
private const val REALM_COMMAND_OUTCOME = "com.typewritermc.capability.RealmCommandOutcome"
