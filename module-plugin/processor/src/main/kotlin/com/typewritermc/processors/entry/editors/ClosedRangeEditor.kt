package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.fullName
import com.typewritermc.processors.whenClassIs
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

object ClosedRangeEditor : CustomEditor {
    override val id: String = "closedRange"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean {
        return type whenClassIs ClosedRange::class
    }

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement {
        val argumentType = type.arguments.firstOrNull()?.type?.resolve()
            ?: throw IllegalStateException("Expected ClosedRange to have a single argument")
        val blueprint = DataBlueprint.blueprint(argumentType)
            ?: throw IllegalStateException("Could not find blueprint for type ${argumentType.fullName}")

        return JsonObject(
            mapOf(
                "start" to blueprint.default(),
                "end" to blueprint.default(),
            )
        )
    }

    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint {
        val argumentType = type.arguments.firstOrNull()?.type?.resolve()
            ?: throw IllegalStateException("Expected ClosedRange to have a single argument")
        val blueprint = DataBlueprint.blueprint(argumentType)
            ?: throw IllegalStateException("Could not find blueprint for type ${argumentType.fullName}")

        return DataBlueprint.ObjectBlueprint(
            mapOf(
                "start" to blueprint,
                "end" to blueprint,
            )
        )
    }
}