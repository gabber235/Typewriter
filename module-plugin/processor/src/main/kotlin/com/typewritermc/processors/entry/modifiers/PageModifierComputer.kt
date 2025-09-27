package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.Page
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import com.typewritermc.processors.entry.PrimitiveType
import kotlin.reflect.KClass

object PageModifierComputer : DataModifierComputer<Page> {
    override val annotationClass: KClass<Page> = Page::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: Page): Result<DataModifier> {
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.PrimitiveBlueprint) {
            return failure("Page annotation can only be used on primitive fields")
        }

        if (blueprint.type != PrimitiveType.STRING) {
            return failure("Page annotation can only be used on string fields")
        }

        return ok(DataModifier.Modifier("page", annotation.type.id))
    }
}