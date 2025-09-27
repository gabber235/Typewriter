package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataBlueprint.PrimitiveBlueprint
import com.typewritermc.processors.entry.PrimitiveType
import com.typewritermc.processors.whenClassNameIs
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive

object CronEditor : CustomEditor {
    override val id: String = "cron"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean {
        return type whenClassNameIs "com.typewritermc.engine.paper.utils.CronExpression"
    }

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement =
        JsonPrimitive("0 0 0 1 1 *")

    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint =
        PrimitiveBlueprint(PrimitiveType.STRING)
}