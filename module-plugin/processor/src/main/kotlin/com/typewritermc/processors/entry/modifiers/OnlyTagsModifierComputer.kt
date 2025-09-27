package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import kotlin.reflect.KClass

object OnlyTagsModifierComputer : DataModifierComputer<OnlyTags> {
    override val annotationClass: KClass<OnlyTags> = OnlyTags::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: OnlyTags): Result<DataModifier> {
        // If the field is wrapped in a list or other container, we try if the inner type can be modified
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.CustomBlueprint) {
            return failure("OnlyTags annotation can only be used on Refs (including in lists or maps)!")
        }

        if (blueprint.editor != "ref") {
            return failure("OnlyTags annotation can only be used on Refs (including in lists or maps)!")
        }

        return ok(DataModifier.Modifier("only_tags", annotation.tags.joinToString(",")))
    }
}