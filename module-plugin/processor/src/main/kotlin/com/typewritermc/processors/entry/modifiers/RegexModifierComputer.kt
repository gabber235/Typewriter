package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.Regex
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import com.typewritermc.processors.entry.PrimitiveType
import kotlin.reflect.KClass

object RegexModifierComputer : DataModifierComputer<Regex> {
    override val annotationClass: KClass<Regex> = Regex::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: Regex): Result<DataModifier> {
        // If the field is wrapped in a list or other container, we try if the inner type can be modified
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.PrimitiveBlueprint) {
            return failure("Regex annotation can only be used on strings (including in lists or maps)!")
        }

        if (blueprint.type != PrimitiveType.STRING) {
            return failure("Regex annotation can only be used on strings (including in lists or maps)!")
        }

        return ok(DataModifier.Modifier("regex"))
    }
}