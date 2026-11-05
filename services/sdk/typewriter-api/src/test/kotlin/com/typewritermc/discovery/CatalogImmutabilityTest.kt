package com.typewritermc.discovery

import com.typewritermc.configuration.field
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.catalog.RuleDescriptor
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.DiagnosticTemplate
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId

val CatalogImmutabilityTest by testSuite {
    test("configuration recipes keep their rules and paths when the caller changes the lists it passed") {
        val origin = RuleOrigin(owner = TypeDefinitionId.qualified("test", "owner"), ordinal = 0)
        val segments = mutableListOf<FieldPatternSegment>(FieldPatternSegment.field("name"))
        val targets = mutableListOf(RelativeFieldPattern(segments = segments))
        val rules =
            mutableListOf(
                OwnedRule(
                    id = RuleId(origin = origin, localIndex = 0),
                    descriptor = RuleDescriptor(predicate = ExpressionNode.UNKNOWN),
                    diagnostic =
                        DiagnosticTemplate(
                            code = "code",
                            message = "message",
                            severity = DiagnosticSeverity.ERROR,
                            targets = targets,
                        ),
                ),
            )
        val source =
            ConfigurationRecipe(
                origin = origin,
                relativePath = RelativeFieldPattern(segments = segments),
                representationCondition = null,
                rules = rules,
            )

        segments += FieldPatternSegment.ITEMS
        targets.clear()
        rules.clear()

        source.relativePath.segments shouldBe listOf(FieldPatternSegment.field("name"))
        source.rules
            .single()
            .diagnostic.targets
            .single()
            .segments shouldBe listOf(FieldPatternSegment.field("name"))
    }
}
