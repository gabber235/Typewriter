package com.typewritermc.processors

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSFile
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.typewritermc.core.extension.annotations.Factory
import com.typewritermc.core.extension.annotations.Named
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.processors.entry.blueprintJson
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement

class DependencyInjectionProcessor(
    private val json: SharedJsonManager,
    private val logger: KSPLogger,
) : PartProcessor {
    override fun process(resolver: Resolver): List<KSAnnotated> {
        val singletons = resolver.getSymbolsWithAnnotation(Singleton::class.qualifiedName!!).toList()
        val factories = resolver.getSymbolsWithAnnotation(Factory::class.qualifiedName!!).toList()

        val blueprints = mutableListOf<JsonElement>()
        blueprints += singletons
            .filterIsInstance<KSClassDeclaration>()
            .map { generateBlueprint(it, SerializableType.SINGLETON) }
        blueprints += factories
            .filterIsInstance<KSClassDeclaration>()
            .map { generateBlueprint(it, SerializableType.FACTORY) }

        blueprints += singletons
            .filterIsInstance<KSFunctionDeclaration>()
            .map { generateBlueprint(it, SerializableType.SINGLETON) }
        blueprints += factories
            .filterIsInstance<KSFunctionDeclaration>()
            .map { generateBlueprint(it, SerializableType.FACTORY) }

        logger.warn("Generated blueprints for ${blueprints.size} dependency injection")

        json.updateSection("dependencyInjections", JsonArray(blueprints))
        return singletons + factories
    }

    @OptIn(KspExperimental::class)
    private fun generateBlueprint(clazz: KSClassDeclaration, type: SerializableType): JsonElement {
        logger.info("Generating $type blueprint for ${clazz.simpleName.asString()}")

        val className = clazz.binaryNameOrNull ?: throw IllegalClassTypeException(clazz.simpleName.asString())
        val name = clazz.getAnnotationsByType(Named::class).firstOrNull()?.value

        val blueprint = DependencyInjectionClassInfo(
            className = className,
            type = type,
            name = name,
        )

        return blueprintJson.encodeToJsonElement<DependencyInjectionBlueprint>(blueprint)
    }

    @OptIn(KspExperimental::class)
    private fun generateBlueprint(function: KSFunctionDeclaration, type: SerializableType): JsonElement {
        logger.info("Generating dependency injection blueprint for ${function.fullName}")

        val parent = function.parent
        if (parent !is KSFile) throw MustBeTopLevelFunctionException("Dependency injections", function.fullName)

        val className = parent.className
        val name = function.getAnnotationsByType(Named::class).firstOrNull()?.value

        val blueprint = DependencyInjectionMethodInfo(
            className = className,
            methodName = function.simpleName.asString(),
            type = type,
            name = name,
        )

        return blueprintJson.encodeToJsonElement<DependencyInjectionBlueprint>(blueprint)
    }
}

@Serializable
sealed interface DependencyInjectionBlueprint {
    val className: String
    val type: SerializableType
    val name: String?
}

@Serializable
@SerialName("class")
data class DependencyInjectionClassInfo(
    override val className: String,
    override val type: SerializableType,
    override val name: String?,
) : DependencyInjectionBlueprint

@Serializable
@SerialName("method")
data class DependencyInjectionMethodInfo(
    override val className: String,
    val methodName: String,
    override val type: SerializableType,
    override val name: String?,
) : DependencyInjectionBlueprint

@Serializable
enum class SerializableType {
    @SerialName("singleton")
    SINGLETON,

    @SerialName("factory")
    FACTORY,
}