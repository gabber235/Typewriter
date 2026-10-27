package com.typewritermc.expression.shortcuts

import com.typewritermc.authoring.Availability
import com.typewritermc.configuration.ConfigurationCollectionScope
import com.typewritermc.configuration.DefaultConfigurationCollectionScope
import com.typewritermc.configuration.DefaultPredicateReasoner
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.FixtureReads
import com.typewritermc.expression.eq
import com.typewritermc.expression.field
import com.typewritermc.expression.input
import com.typewritermc.expression.isNull
import com.typewritermc.expression.literal
import com.typewritermc.expression.or
import com.typewritermc.expression.testPortableTypes
import com.typewritermc.testkit.durationField
import com.typewritermc.testkit.integerField
import com.typewritermc.testkit.listField
import com.typewritermc.testkit.nullableIntegerField
import com.typewritermc.testkit.nullableTextField
import com.typewritermc.testkit.textField
import com.typewritermc.testkit.timestampField
import com.typewritermc.types.declared
import com.typewritermc.types.duration
import com.typewritermc.types.integerScalar
import com.typewritermc.types.template
import com.typewritermc.types.timestamp
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.TypeDefinitionId
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

internal val CONFIGURED_VALUE = ExpressionBindingId(value = "configured_value")

internal val OWNER = TypeDefinitionId.declared("0b9cbb2bb5d44d2c9f53d7b4a1d0f6e1")

/** The predicates [configure] declares on one configured value. */
internal fun rules(configure: (ConfigurationCollectionScope) -> Unit): List<ExpressionNode> =
    DefaultConfigurationCollectionScope(OWNER)
        .also(configure)
        .collected()
        .recipes
        .flatMap { it.rules }
        .map { it.descriptor.predicate }

/** The single predicate [configure] declares. */
internal fun rule(configure: (ConfigurationCollectionScope) -> Unit): ExpressionNode = rules(configure).single()

/** Whether the rule holds for the configured [value]. */
internal infix fun ExpressionNode.holdsFor(value: DataValue): Boolean {
    val result =
        with(FixtureReads) {
            DefaultExpressionEvaluator(
                ExpressionValueReader { error("Rule tests bind unlocated values only.") },
                testPortableTypes(),
            ).evaluateScoped(
                this@holdsFor,
                ExpressionBindings(emptyMap()),
                mapOf(CONFIGURED_VALUE to value),
                EvaluationBudget(maxSteps = 10_000, maxCollectionItems = 10_000),
            )
        }
    return ((result as Availability.Available).value as DataValue.BooleanWrapper).value
}
