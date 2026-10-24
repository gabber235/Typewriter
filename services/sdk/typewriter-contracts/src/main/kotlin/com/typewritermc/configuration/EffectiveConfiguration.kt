package com.typewritermc.configuration

import com.typewritermc.types.catalog.AppliedSchema
import kotlinx.serialization.Serializable

@Serializable
data class ConfigurationRecipe(
    val origin: RuleOrigin,
    val relativePath: RelativeFieldPattern,
    val representationCondition: RepresentationKind?,
    val rules: List<OwnedRule>,
)

@Serializable
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
