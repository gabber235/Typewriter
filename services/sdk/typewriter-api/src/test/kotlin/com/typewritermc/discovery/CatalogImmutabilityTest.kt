package com.typewritermc.discovery

import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.DiagnosticTemplate
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RuleDescriptor
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId

val CatalogImmutabilityTest by testSuite {
    test("assembled configuration recipes reject outer and nested collection mutation") {
        val origin = RuleOrigin(owner = TypeDefinitionId.qualified("test", "owner"), ordinal = 0)
        val segments = mutableListOf<FieldPatternSegment>(FieldPatternSegment.Field("name"))
        val targets = mutableListOf(RelativeFieldPattern(segments))
        val rules =
            mutableListOf(
                OwnedRule(
                    RuleId(origin = origin, localIndex = 0),
                    RuleDescriptor(ExpressionNode.UNKNOWN),
                    DiagnosticTemplate("code", "message", DiagnosticSeverity.Error, targets),
                ),
            )
        val source = ConfigurationRecipe(origin, RelativeFieldPattern(segments), null, rules)

        val retained = source.immutableCopy()
        segments += FieldPatternSegment.Items
        targets.clear()
        rules.clear()

        retained.relativePath.segments shouldBe listOf(FieldPatternSegment.Field("name"))
        retained.rules
            .single()
            .diagnostic.targets
            .single()
            .segments shouldBe listOf(FieldPatternSegment.Field("name"))
        shouldThrow<UnsupportedOperationException> {
            @Suppress("UNCHECKED_CAST")
            (retained.rules as MutableList<OwnedRule>).clear()
        }
        shouldThrow<UnsupportedOperationException> {
            @Suppress("UNCHECKED_CAST")
            (retained.relativePath.segments as MutableList<FieldPatternSegment>).clear()
        }
    }
}
