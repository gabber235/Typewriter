package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlin.reflect.KClass

object HelpModifierComputer : DataModifierComputer<Help> {
    override val annotationClass: KClass<Help> = Help::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: Help): Result<DataModifier> {
        // Prefer localization key over text fallback
        val data = when {
            annotation.key.isNotEmpty() -> JsonObject(mapOf(
                "key" to JsonPrimitive(annotation.key)
            ))
            annotation.text.isNotEmpty() -> JsonPrimitive(annotation.text)
            else -> JsonPrimitive("")
        }
        return ok(DataModifier.Modifier("help", data))
    }
}