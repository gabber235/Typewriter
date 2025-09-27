package com.typewritermc.processors.entry.modifiers

import com.google.devtools.ksp.processing.KSPLogger
import com.google.devtools.ksp.processing.Resolver
import com.typewritermc.core.extension.annotations.MaterialProperties
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.processors.entry.*
import kotlin.reflect.KClass

object MaterialPropertiesModifierComputer : DataModifierComputer<MaterialProperties> {
    override val annotationClass: KClass<MaterialProperties> = MaterialProperties::class

    context(logger: KSPLogger, resolver: Resolver)
    override fun compute(blueprint: DataBlueprint, annotation: MaterialProperties): Result<DataModifier> {
        // If the field is wrapped in a list or other container, we try if the inner type can be modified
        innerCompute(blueprint, annotation)?.let { return ok(it) }

        if (blueprint !is DataBlueprint.CustomBlueprint) {
            return failure("MaterialProperties annotation can only be used on custom fields")
        }
        if (blueprint.editor != "material") {
            return failure("MaterialProperties annotation can only be used materials (not on ${blueprint.editor})")
        }

        return ok(
            DataModifier.Modifier(
                "material_properties",
                annotation.properties.joinToString(";") { it.name.lowercase() }
            ))
    }
}