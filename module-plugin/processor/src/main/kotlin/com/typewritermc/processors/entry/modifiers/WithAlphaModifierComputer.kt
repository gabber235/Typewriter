package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.WithAlpha
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import kotlin.reflect.KClass

object WithAlphaModifierComputer : DataModifierComputer<WithAlpha> {
    override val annotationClass: KClass<WithAlpha> = WithAlpha::class

    context(KSPLogger, Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: WithAlpha): Result<DataModifier> {
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.CustomBlueprint) {
            return failure("WithAlpha annotation can only be used on color fields!")
        }
        if (blueprint.editor != "color") {
            return failure("WithAlpha annotation can only be used on color fields!")
        }

        return ok(DataModifier.Modifier("with_alpha"))
    }
}