package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import kotlin.reflect.KClass

object WithRotationModifierComputer : DataModifierComputer<WithRotation> {
    override val annotationClass: KClass<WithRotation> = WithRotation::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: WithRotation): Result<DataModifier> {
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.CustomBlueprint) {
            return failure("WithRotation annotation can only be used on positions or coordinates (including in lists or maps)!")
        }
        if (blueprint.editor != "position" && blueprint.editor != "coordinate") {
            return failure("WithRotation annotation can only be used on positions or coordinates (including in lists or maps)!")
        }

        return ok(DataModifier.Modifier("with_rotation"))
    }
}