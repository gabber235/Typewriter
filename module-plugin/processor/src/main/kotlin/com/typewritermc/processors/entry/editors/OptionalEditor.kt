package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataBlueprint.ObjectBlueprint
import com.typewritermc.processors.entry.DataBlueprint.PrimitiveBlueprint
import com.typewritermc.processors.entry.PrimitiveType
import com.typewritermc.processors.fullName
import com.typewritermc.processors.whenClassIs
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.util.*

object OptionalEditor : CustomEditor {
    override val id: String = "optional"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean {
        return type whenClassIs Optional::class
    }

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement {
        val argumentType = type.arguments.firstOrNull()?.type?.resolve()
            ?: throw IllegalStateException("Expected Optional to have a single argument")
        val blueprint = DataBlueprint.blueprint(argumentType)
            ?: throw IllegalStateException("Could not find blueprint for type ${argumentType.fullName}")
        return JsonObject(
            mapOf(
                "enabled" to JsonPrimitive(false),
                "value" to blueprint.default()
            )
        )
    }

    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint {
        val argumentType = type.arguments.firstOrNull()?.type?.resolve()
            ?: throw IllegalStateException("Expected Optional to have a single argument")
        val blueprint = DataBlueprint.blueprint(argumentType)
            ?: throw IllegalStateException("Could not find blueprint for type ${argumentType.fullName}")
        return ObjectBlueprint(
            mapOf(
                "enabled" to PrimitiveBlueprint(PrimitiveType.BOOLEAN),
                "value" to blueprint
            )
        )
    }
}