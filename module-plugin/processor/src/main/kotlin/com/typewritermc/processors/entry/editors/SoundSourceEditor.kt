package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataBlueprint.ObjectBlueprint
import com.typewritermc.processors.entry.DataBlueprint.PrimitiveBlueprint
import com.typewritermc.processors.entry.PrimitiveType
import com.typewritermc.processors.whenClassNameIs
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

object SoundSourceEditor : CustomEditor {
    override val id: String = "soundSource"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean {
        return type whenClassNameIs "com.typewritermc.engine.paper.utils.SoundSource"
    }

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement {
        return JsonObject(
            mapOf(
                "type" to JsonPrimitive("self"),
                "entryId" to JsonPrimitive(""),
                "location" to JsonObject(
                    mapOf(
                        "world" to JsonPrimitive(""),
                        "x" to JsonPrimitive(0.0),
                        "y" to JsonPrimitive(0.0),
                        "z" to JsonPrimitive(0.0),
                        "yaw" to JsonPrimitive(0.0),
                        "pitch" to JsonPrimitive(0.0),
                    )
                )
            )
        )
    }

    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint {
        return ObjectBlueprint(
            mapOf(
                "type" to PrimitiveBlueprint(PrimitiveType.STRING),
                "entryId" to PrimitiveBlueprint(PrimitiveType.STRING),
                "location" to ObjectBlueprint(
                    mapOf(
                        "world" to PrimitiveBlueprint(PrimitiveType.STRING),
                        "x" to PrimitiveBlueprint(PrimitiveType.DOUBLE),
                        "y" to PrimitiveBlueprint(PrimitiveType.DOUBLE),
                        "z" to PrimitiveBlueprint(PrimitiveType.DOUBLE),
                        "yaw" to PrimitiveBlueprint(PrimitiveType.DOUBLE),
                        "pitch" to PrimitiveBlueprint(PrimitiveType.DOUBLE),
                    )
                )
            )
        )
    }
}