package com.typewritermc.configuration

import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.type_catalog.AppliedSchema
import skirout.editor.v1.type_catalog.RelativeFieldPattern

data class EffectiveFieldConfiguration(
    val guarantees: List<OwnedRule>,
)

data class EffectiveConfiguration(
    val fields: Map<RelativeFieldPattern, EffectiveFieldConfiguration>,
)

fun List<ConfigurationRecipe>.bindTo(schema: AppliedSchema): EffectiveConfiguration {
    val kind = schema.representation.kind()
    val fields =
        asSequence()
            .filter { it.representationCondition == null || it.representationCondition == kind }
            .groupBy(ConfigurationRecipe::relativePath)
            .mapValues { (_, recipes) -> EffectiveFieldConfiguration(recipes.flatMap(ConfigurationRecipe::rules)) }
    return EffectiveConfiguration(fields)
}
