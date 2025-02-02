package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.IgnoreContextKeyBlueprint
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.DataBlueprint
import com.typewritermc.processors.entry.DataModifier
import com.typewritermc.processors.entry.DataModifierComputer
import kotlin.reflect.KClass

object IgnoreContextKeyBlueprintModifierComputer : DataModifierComputer<IgnoreContextKeyBlueprint> {
    override val annotationClass: KClass<IgnoreContextKeyBlueprint> = IgnoreContextKeyBlueprint::class

    context(KSPLogger, Resolver)
    override fun compute(
        blueprint: DataBlueprint,
        annotation: IgnoreContextKeyBlueprint
    ): Result<DataModifier> {
        // If the field is wrapped in a list or other container, we try if the inner type can be modified
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.CustomBlueprint) {
            return failure("IgnoreContextKeyBlueprint annotation can only be used on `InteractionContextKey`")
        }
        if (blueprint.editor != "entryInteractionContextKey") {
            return failure("IgnoreContextKeyBlueprint annotation can only be used on `InteractionContextKey`")
        }

        return ok(DataModifier.Modifier("ignore_context_key_blueprint"))
    }
}