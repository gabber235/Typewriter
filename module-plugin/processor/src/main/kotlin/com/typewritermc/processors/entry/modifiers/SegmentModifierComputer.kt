package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.*
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlin.reflect.KClass

object SegmentModifierComputer : DataModifierComputer<Segments> {
    override val annotationClass: KClass<Segments> = Segments::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: Segments): Result<DataModifier> {
        if (blueprint !is DataBlueprint.ListBlueprint) {
            return failure("Segment annotation can only be used on lists")
        }

        val type = blueprint.type
        if (type !is DataBlueprint.ObjectBlueprint) {
            return failure("Segment annotation can only be used on lists of objects")
        }

        val startFrame = type.fields["startFrame"]
        val endFrame = type.fields["endFrame"]
        if (startFrame !is DataBlueprint.PrimitiveBlueprint || endFrame !is DataBlueprint.PrimitiveBlueprint) {
            return failure("Segment annotation can only be used on lists of objects with startFrame and endFrame fields")
        }

        if (startFrame.type != PrimitiveType.INTEGER || endFrame.type != PrimitiveType.INTEGER) {
            return failure("Segment annotation can only be used on lists of objects with startFrame and endFrame fields of type int")
        }

        val color = annotation.color
        val icon = annotation.icon

        val data = JsonObject(
            mapOf(
                "color" to JsonPrimitive(color),
                "icon" to JsonPrimitive(icon),
            )
        )

        return ok(DataModifier.InnerModifier(DataModifier.Modifier("segment", data)))
    }
}