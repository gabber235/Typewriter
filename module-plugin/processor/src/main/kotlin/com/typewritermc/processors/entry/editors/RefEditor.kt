package com.typewritermc.processors.entry.editors

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.Variance
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.CustomEditor
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataBlueprint.PrimitiveBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.PrimitiveType
import com.typewritermc.processors.fullName
import com.typewritermc.processors.whenClassIs
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull

object RefEditor : CustomEditor {
    override val id: String = "ref"

    context(logger: KSPLogger, resolver: Resolver)
    override fun accept(type: KSType): Boolean = type whenClassIs Ref::class

    context(logger: KSPLogger, resolver: Resolver) override fun default(type: KSType): JsonElement = JsonNull
    context(logger: KSPLogger, resolver: Resolver) override fun shape(type: KSType): DataBlueprint {
        return PrimitiveBlueprint(PrimitiveType.STRING)
    }

    context(logger: KSPLogger, resolver: Resolver)
    override fun validateDefault(type: KSType, default: JsonElement): Result<Unit> {
        if (default is JsonNull) return ok(Unit)
        return super.validateDefault(type, default)
    }

    @OptIn(KspExperimental::class)
    context(logger: KSPLogger, resolver: Resolver)
    override fun modifiers(type: KSType): List<DataModifier> {
        val argument = type.arguments.firstOrNull() ?: throw IllegalArgumentException(
            "Ref requires a single type argument, but found none"
        )
        val tag = when (argument.variance) {
            // When you have Ref<out Entry> it makes it a Ref<*> which doesn't have a type.
            Variance.STAR -> "entry"
            else -> {
                val resolvedType = argument.type?.resolve()
                    ?: throw IllegalArgumentException("Ref requires a single type argument, but found none")
                val tags =
                    resolvedType.declaration.getAnnotationsByType(Tags::class).firstOrNull()?.tags
                        ?: throw NoTagsFoundException(
                            resolvedType,
                            type
                        )
                if (tags.isEmpty()) throw NoTagsFoundException(resolvedType, type)
                tags.first()
            }
        }

        return listOf(DataModifier.Modifier("entry", tag))
    }
}

class NoTagsFoundException(klass: KSType, origin: KSType) : Exception(
    """|No tags found for ${klass.declaration.simpleName.asString()}
    |${origin.fullName} tried to reference ${klass.fullName} but it does not have the @Tags annotation.
    |To be able to reference ${klass.fullName}, it needs to have the @Tags annotation with at least one tag.
""".trimMargin()
)