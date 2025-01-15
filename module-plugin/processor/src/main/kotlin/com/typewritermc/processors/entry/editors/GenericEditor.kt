package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.core.utils.Generic
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.PrimitiveType
import com.typewritermc.processors.whenClassIs
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull

object GenericEditor : CustomEditor {
    override val id: String = "generic"

    override fun accept(type: KSType): Boolean = type whenClassIs Generic::class

    context(KSPLogger, Resolver) override fun default(type: KSType): JsonElement = JsonNull

    context(KSPLogger, Resolver) override fun shape(type: KSType): DataBlueprint = DataBlueprint.PrimitiveBlueprint(
        PrimitiveType.STRING)
}