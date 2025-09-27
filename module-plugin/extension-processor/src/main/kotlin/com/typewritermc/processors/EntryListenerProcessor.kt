package com.typewritermc.processors

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSFile
import com.google.devtools.ksp.symbol.KSFunctionDeclaration
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.loader.ListenerPriority
import com.typewritermc.processors.entry.blueprintJson
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.encodeToJsonElement

class EntryListenerProcessor(
    private val json: SharedJsonManager,
    private val logger: KSPLogger,
) : PartProcessor {
    override fun process(resolver: Resolver): List<KSAnnotated> {
        val symbols = resolver.getSymbolsWithAnnotation(EntryListener::class.qualifiedName!!)
        val listeners = symbols.filterIsInstance<KSFunctionDeclaration>()
            .map {
                with(resolver) {
                    generateListenerBlueprint(it)
                }
            }
            .toList()

        logger.warn("Generated blueprints for ${listeners.size} entry listeners")

        json.updateSection("entryListeners", JsonArray(listeners))
        return symbols.toList()
    }

    context(resolver: Resolver)
    @OptIn(KspExperimental::class)
    private fun generateListenerBlueprint(function: KSFunctionDeclaration): JsonElement {
        logger.info("Generating entry listener blueprint for ${function.fullName}")

        val parent = function.parent
        if (parent !is KSFile) throw MustBeTopLevelFunctionException("Entry listeners", function.fullName)

        val listener = function.getAnnotationsByType(EntryListener::class).first()
        val entry = listener.annotationClassValue { entry }
        val entryAnnotation = entry.declaration.getAnnotationsByType(Entry::class).firstOrNull()
            ?: throw EntryNotFoundException("Listener", function.fullName, entry.fullName)

        val blueprint = EntryListenerBlueprint(
            entryBlueprintId = entryAnnotation.name,
            entryClassName = entry.fullName,
            className = parent.className,
            methodName = function.simpleName.asString(),
            priority = listener.priority,
            ignoreCancelled = listener.ignoreCancelled,
            arguments = function.parameters.map { it.type.resolve().fullName },
        )

        return blueprintJson.encodeToJsonElement(blueprint)
    }
}

@Serializable
data class EntryListenerBlueprint(
    val entryBlueprintId: String,
    val entryClassName: String,
    val className: String,
    val methodName: String,
    val priority: ListenerPriority,
    val ignoreCancelled: Boolean,
    val arguments: List<String>,
)

class MustBeTopLevelFunctionException(type: String, function: String) :
    Exception("Function $function is not in a class. $type must be a top-level function")
