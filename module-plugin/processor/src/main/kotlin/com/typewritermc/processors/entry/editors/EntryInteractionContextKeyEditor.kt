package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.getClassDeclarationByName
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.EntryInteractionContextKey
import com.typewritermc.processors.entry.CouldNotBuildBlueprintException
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.PrimitiveType
import com.typewritermc.processors.whenClassIs
import kotlinx.serialization.json.JsonElement

object EntryInteractionContextKeyEditor : CustomEditor {
    override val id: String = "entryInteractionContextKey"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean = type whenClassIs EntryInteractionContextKey::class

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement =
        shape(type).default()

    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint {
        val ref = resolver.getClassDeclarationByName<Ref<*>>()?.asStarProjectedType()
            ?: throw CouldNotBuildBlueprintException("Could not find Ref")
        val refBlueprint =
            DataBlueprint.blueprint(ref) ?: throw CouldNotBuildBlueprintException("Could not find Ref blueprint")

        val string = DataBlueprint.PrimitiveBlueprint(PrimitiveType.STRING)

        return DataBlueprint.ObjectBlueprint(
            mapOf(
                "ref" to refBlueprint,
                "keyClass" to string,
                "key" to string,
            )
        )
    }
}