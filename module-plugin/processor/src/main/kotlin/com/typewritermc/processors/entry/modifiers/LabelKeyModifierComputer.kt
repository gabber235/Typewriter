package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.LabelKey
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import kotlin.reflect.KClass

object LabelKeyModifierComputer : DataModifierComputer<LabelKey> {
    override val annotationClass: KClass<LabelKey> = LabelKey::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: LabelKey): Result<DataModifier> {
        return ok(DataModifier.Modifier("labelKey", annotation.value))
    }
}
