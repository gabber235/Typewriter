package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataBlueprint.PrimitiveBlueprint
import com.typewritermc.processors.entry.PrimitiveType
import com.typewritermc.processors.whenClassIs
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import java.time.Duration

object DurationEditor : CustomEditor {
    override val id: String = "duration"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean {
        return type whenClassIs Duration::class
    }

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement = JsonPrimitive(1000)
    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint =
        PrimitiveBlueprint(PrimitiveType.INTEGER)

    context(logger: KSPLogger, resolver: Resolver) override fun validateDefault(
        type: KSType,
        default: JsonElement
    ): Result<Unit> {
        val result = super.validateDefault(type, default)
        if (result.isFailure) return result
        val duration = Duration.ofMillis(default.jsonPrimitive.long)
        if (duration.isNegative) return failure("The duration default value for %s must be positive")
        return ok(Unit)
    }
}