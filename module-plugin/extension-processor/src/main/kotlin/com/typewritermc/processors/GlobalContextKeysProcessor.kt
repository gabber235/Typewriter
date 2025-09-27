package com.typewritermc.processors

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.typewritermc.core.extension.annotations.GlobalKey
import com.typewritermc.processors.entry.CouldNotBuildBlueprintException
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.FailedToGenerateBlueprintException
import com.typewritermc.processors.entry.blueprintJson
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement

class GlobalContextKeysProcessor(
    private val json: SharedJsonManager,
    private val logger: KSPLogger,
) : PartProcessor {
    override fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(GlobalKey::class.qualifiedName!!).toList()

        val globalKeys = symbols
            .filterIsInstance<KSClassDeclaration>()
            .map {
                with(logger) {
                    with(resolver) {
                        generateGlobalKeyBlueprint(it)
                    }
                }
            }
            .toList()

        logger.warn("Generated blueprints for ${globalKeys.size} global keys")
        json.updateSection("globalContextKeys", JsonArray(globalKeys))

        return symbols
    }

    context(logger: KSPLogger, resolver: Resolver)
    @OptIn(KspExperimental::class)
    private fun generateGlobalKeyBlueprint(clazz: KSClassDeclaration): JsonElement {
        logger.info("Generating global key blueprint for ${clazz.simpleName.asString()}")

        val annotation = clazz.getAnnotationsByType(GlobalKey::class).first()
        val name = clazz.simpleName.asString()
        val targetClass = annotation.annotationClassValue { klass }
        val klassName = clazz.fullName

        val blueprint = GlobalKeyBlueprint(
            name = name,
            klassName = klassName,
            blueprint = DataBlueprint.blueprint(targetClass) ?: throw FailedToGenerateBlueprintException(
                targetClass.declaration as KSClassDeclaration,
                CouldNotBuildBlueprintException(targetClass.fullName)
            )
        )

        return blueprintJson.encodeToJsonElement<GlobalKeyBlueprint>(blueprint)
    }
}

@Serializable
class GlobalKeyBlueprint(
    val name: String,
    val klassName: String,
    val blueprint: DataBlueprint,
)