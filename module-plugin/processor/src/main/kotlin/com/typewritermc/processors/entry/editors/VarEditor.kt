package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.fullName
import com.typewritermc.processors.whenClassNameIs
import kotlinx.serialization.json.JsonElement

object VarEditor : CustomEditor {
    override val id: String = "var"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean {
        return type.whenClassNameIs("com.typewritermc.engine.paper.entry.entries.Var")
    }

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement {
        val argumentType = type.arguments.firstOrNull()?.type?.resolve()
            ?: throw IllegalStateException("Expected Optional to have a single argument")
        val blueprint = DataBlueprint.blueprint(argumentType)
            ?: throw IllegalStateException("Could not find blueprint for type ${argumentType.fullName}")
        return blueprint.default()
    }

    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint {
        val argumentType = type.arguments.firstOrNull()?.type?.resolve()
            ?: throw IllegalStateException("Expected Optional to have a single argument")
        val blueprint = DataBlueprint.blueprint(argumentType)
            ?: throw IllegalStateException("Could not find blueprint for type ${argumentType.fullName}")
        return blueprint
    }
}