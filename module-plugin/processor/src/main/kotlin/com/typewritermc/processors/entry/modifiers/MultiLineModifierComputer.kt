package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.MultiLine
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import com.typewritermc.processors.entry.PrimitiveType
import kotlin.reflect.KClass

object MultiLineModifierComputer : DataModifierComputer<MultiLine> {
    override val annotationClass: KClass<MultiLine> = MultiLine::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: MultiLine): Result<DataModifier> {
        // If the field is wrapped in a list or other container, we try if the inner type can be modified
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.PrimitiveBlueprint) {
            return failure("MultiLine annotation can only be used on strings")
        }
        if (blueprint.type != PrimitiveType.STRING) {
            return failure("MultiLine annotation can only be used on strings")
        }

        return ok(DataModifier.Modifier("multiline"))
    }
}