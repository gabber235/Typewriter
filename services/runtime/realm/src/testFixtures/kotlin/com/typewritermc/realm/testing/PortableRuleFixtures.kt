package com.typewritermc.realm.testing

import com.typewritermc.configuration.CollectedConfiguration
import com.typewritermc.configuration.ConfigurationCollectionScope
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.configuration.field
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.expression.eq
import com.typewritermc.expression.literal
import com.typewritermc.expression.not
import com.typewritermc.formula.VarDefinition
import com.typewritermc.types.member
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin

/** The code of [notOneRule]'s finding. */
const val NOT_ONE = "not_one"

/**
 * A portable rule an extension registers on a plainly written value: where that value is a whole number, it must not
 * be 1. Whether a value is a whole number depends on its type, which may be a content type declared elsewhere.
 */
fun notOneRule(origin: ProviderOrigin): OwnedConfiguration {
    val target = VarDefinition.id.member("Value")
    return OwnedConfiguration(origin, target, NotOneRule(RuleOrigin(owner = target, ordinal = 0)))
}

private class NotOneRule(
    private val origin: RuleOrigin,
) : ConfigurationProvider {
    override fun collect(scope: ConfigurationCollectionScope): CollectedConfiguration {
        val path = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("value")))
        val notOne =
            (com.typewritermc.expression.input<Int>(ExpressionBindingId(value = "configured_value")) eq literal(1)).not().toNode()
        val rule =
            OwnedRule(
                id = RuleId(origin = origin, localIndex = 0),
                descriptor = RuleDescriptor(predicate = notOne),
                diagnostic =
                    DiagnosticTemplate(
                        code = NOT_ONE,
                        message = "The value must not be 1.",
                        severity = DiagnosticSeverity.ERROR,
                        targets = listOf(path),
                    ),
            )
        return CollectedConfiguration(
            recipes =
                listOf(
                    ConfigurationRecipe(
                        origin = origin,
                        relativePath = path,
                        representationCondition = RepresentationKind.INTEGER,
                        rules = listOf(rule),
                    ),
                ),
            checks = emptyList(),
        )
    }
}
