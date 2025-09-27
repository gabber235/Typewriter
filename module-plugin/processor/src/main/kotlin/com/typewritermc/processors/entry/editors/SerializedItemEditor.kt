package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.whenClassNameIs
import kotlinx.serialization.json.JsonElement

object SerializedItemEditor : CustomEditor {
    override val id: String = "serialized_item"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean {
        return type whenClassNameIs "com.typewritermc.engine.paper.utils.item.SerializedItem"
    }

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement =
        shape(type).default()

    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint {
        return DataBlueprint.ObjectBlueprint.blueprint(type)
            ?: throw IllegalStateException("Could not find blueprint for $type")
    }
}