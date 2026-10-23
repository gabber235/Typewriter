package com.typewritermc.expression.shortcuts

import com.typewritermc.authoring.Availability
import com.typewritermc.configuration.ConfigurationCollectionScope
import com.typewritermc.configuration.DefaultConfigurationCollectionScope
import com.typewritermc.configuration.DefaultPredicateReasoner
import com.typewritermc.configuration.DurationField
import com.typewritermc.configuration.Integer
import com.typewritermc.configuration.ListField
import com.typewritermc.configuration.NullableField
import com.typewritermc.configuration.Text
import com.typewritermc.configuration.TimestampField
import com.typewritermc.configuration.root
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.FixtureReads
import com.typewritermc.expression.eq
import com.typewritermc.expression.field
import com.typewritermc.expression.input
import com.typewritermc.expression.literal
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.declared
import com.typewritermc.types.duration
import com.typewritermc.types.integerScalar
import com.typewritermc.types.nullable
import com.typewritermc.types.template
import com.typewritermc.types.timestamp
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import kotlin.reflect.KClass
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/*
 * Configuration rule helpers build their predicates from the shortcuts. These tests evaluate those predicates and check
 * that DefaultPredicateReasoner finds contradictory bounds in exactly the shapes the helpers and hand written
 * comparisons with literals lower to.
 */
val RuleShortcutReasoningTest by testSuite {
    val reasoner = DefaultPredicateReasoner()

    test("rule helpers accept and reject configured values like their former rule nodes") {
        rule { integerField(it).minimum(3) } holdsFor number(5) shouldBe true
        rule { integerField(it).minimum(5, inclusive = false) } holdsFor number(5) shouldBe false
        rule { integerField(it).between(1, 3) } holdsFor number(4) shouldBe false
        rule { integerField(it).multipleOf(5) } holdsFor number(15) shouldBe true
        rule { integerField(it).positive() } holdsFor number(0) shouldBe false
        rule { textField(it).endsWith(".json") } holdsFor text("data.json") shouldBe true
        rule { textField(it).startsWith("re") } holdsFor text("do") shouldBe false
        rule { textField(it).lengthBetween(2, 4) } holdsFor text("😀😀") shouldBe true
        rule { textField(it).nonBlank() } holdsFor text(" 　") shouldBe false
        rule { textField(it).singleLine() } holdsFor text("a\nb") shouldBe false
        rule { textField(it).maximumLines(2) } holdsFor text("a\r\nb") shouldBe true
        rule { textField(it).regex("[a-z]+") } holdsFor text("abc") shouldBe true
        rule { textField(it).oneOf(listOf("a", "b")) } holdsFor text("b") shouldBe true
        rule { listField(it).nonEmpty() } holdsFor list() shouldBe false
        rule { listField(it).unique() } holdsFor numbers(1, 2, 1) shouldBe false
        rule { listField(it).maximumItems(2) } holdsFor numbers(1, 2) shouldBe true
        rule { durationField(it).nonNegative() } holdsFor DataValue.duration((-1).seconds) shouldBe false
        rule { timestampField(it).notBefore(Instant.parse("2024-01-01T00:00:00Z")) } holdsFor
            DataValue.timestamp(Instant.parse("2024-01-01T00:00:00Z")) shouldBe true
        rule { nullableTextField(it).whenPresent { minimumLength(2) } } holdsFor DataValue.NULL shouldBe true
    }

    test("numeric bounds that leave no value contradict, touching inclusive bounds do not") {
        reasoner.contradicts(rules { integerField(it).apply { minimum(10) }.maximum(5) }) shouldBe true
        reasoner.contradicts(rules { integerField(it).apply { minimum(5) }.maximum(5) }) shouldBe false
        reasoner.contradicts(rules { integerField(it).apply { minimum(5, inclusive = false) }.maximum(5) }) shouldBe true
        reasoner.contradicts(rules { integerField(it).apply { between(1, 3) }.minimum(4) }) shouldBe true
        reasoner.contradicts(rules { integerField(it).apply { positive() }.maximum(0) }) shouldBe true
    }

    test("size bounds of text and collections contradict") {
        reasoner.contradicts(rules { textField(it).apply { minimumLength(10) }.maximumLength(5) }) shouldBe true
        reasoner.contradicts(rules { textField(it).apply { lengthBetween(2, 4) }.maximumLength(1) }) shouldBe true
        reasoner.contradicts(rules { listField(it).apply { minimumItems(3) }.maximumItems(2) }) shouldBe true
        reasoner.contradicts(rules { listField(it).apply { minimumItems(2) }.maximumItems(2) }) shouldBe false
    }

    test("bounds of rules that skip null still contradict") {
        reasoner.contradicts(
            rules { nullableIntegerField(it).whenPresent { minimum(10) } } + rules { integerField(it).maximum(5) },
        ) shouldBe
            true
    }

    test("duration and timestamp bounds contradict on their own scale") {
        reasoner.contradicts(rules { durationField(it).apply { minimum(10.seconds) }.maximum(5.seconds) }) shouldBe true
        reasoner.contradicts(
            rules {
                timestampField(
                    it,
                ).apply { notBefore(Instant.parse("2025-01-01T00:00:00Z")) }.notAfter(Instant.parse("2024-01-01T00:00:00Z"))
            },
        ) shouldBe true
    }

    test("hand written comparisons with literals take part, in either operand order") {
        val value = input<Int>(CONFIGURED_VALUE)
        reasoner.contradicts(listOf((value gt 10).toNode(), (literal(5) gte value).toNode())) shouldBe true
        reasoner.contradicts(listOf((value eq literal(3)).toNode(), (value gt 3).toNode())) shouldBe true
        reasoner.contradicts(listOf((value gt 10).toNode(), (literal(20) gte value).toNode())) shouldBe false
    }

    test("bounds on different subjects never meet") {
        val record = input<Any>(CONFIGURED_VALUE)
        reasoner.contradicts(
            listOf((record.field<Int>("first") gt 10).toNode(), (record.field<Int>("second") lt 5).toNode()),
        ) shouldBe false
        reasoner.contradicts(rules { textField(it).apply { minimumLength(10) }.oneOf(listOf("short")) }) shouldBe false
        reasoner.contradicts(
            listOf((record.field<Int>("first").inRange(1, 3)).toNode(), (record.field<Int>("first") gt 3).toNode()),
        ) shouldBe
            true
    }
}

private val CONFIGURED_VALUE = ExpressionBindingId(value = "configured_value")

private val OWNER = TypeDefinitionId.declared("0b9cbb2bb5d44d2c9f53d7b4a1d0f6e1")

/** The predicates [configure] declares on one configured value. */
private fun rules(configure: (ConfigurationCollectionScope) -> Unit): List<ExpressionNode> =
    DefaultConfigurationCollectionScope(OWNER)
        .also(configure)
        .collected()
        .recipes
        .flatMap { it.rules }
        .map { it.descriptor.predicate }

/** The single predicate [configure] declares. */
private fun rule(configure: (ConfigurationCollectionScope) -> Unit): ExpressionNode = rules(configure).single()

/** Whether the rule holds for the configured [value]. */
private infix fun ExpressionNode.holdsFor(value: DataValue): Boolean {
    val result =
        with(FixtureReads) {
            DefaultExpressionEvaluator(ExpressionValueReader { error("Rule tests bind unlocated values only.") }).evaluateScoped(
                this@holdsFor,
                ExpressionBindings(emptyMap()),
                mapOf(CONFIGURED_VALUE to value),
                EvaluationBudget(maxSteps = 10_000, maxCollectionItems = 10_000),
            )
        }
    return ((result as Availability.Available).value as DataValue.BooleanWrapper).value
}

private val INT = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template

@Suppress("UNCHECKED_CAST")
private fun integerField(scope: ConfigurationCollectionScope): Integer<Int> =
    scope.field(RelativeFieldPattern.root, RepresentationKind.INTEGER, INT, Integer::class as KClass<Integer<Int>>)

private fun textField(scope: ConfigurationCollectionScope): Text =
    scope.field(RelativeFieldPattern.root, RepresentationKind.TEXT, ScalarKind.TEXT.template, Text::class)

@Suppress("UNCHECKED_CAST")
private fun listField(scope: ConfigurationCollectionScope): ListField<Int, Any, Any> =
    scope.field(
        RelativeFieldPattern.root,
        RepresentationKind.LIST,
        StandardTypes.list.template(listOf(INT)),
        ListField::class as KClass<ListField<Int, Any, Any>>,
    )

private fun durationField(scope: ConfigurationCollectionScope): DurationField =
    scope.field(RelativeFieldPattern.root, RepresentationKind.DURATION, ScalarKind.DURATION.template, DurationField::class)

private fun timestampField(scope: ConfigurationCollectionScope): TimestampField =
    scope.field(RelativeFieldPattern.root, RepresentationKind.TIMESTAMP, ScalarKind.TIMESTAMP.template, TimestampField::class)

@Suppress("UNCHECKED_CAST")
private fun nullableTextField(scope: ConfigurationCollectionScope): NullableField<String, Text> =
    scope.field(
        RelativeFieldPattern.root,
        RepresentationKind.TEXT,
        ScalarKind.TEXT.template.nullable(),
        NullableField::class as KClass<NullableField<String, Text>>,
        mapOf(
            skirout.editor.v1.type_catalog.FieldPatternSegment.VALUES to
                com.typewritermc.configuration.NestedConfigurationScope(
                    RepresentationKind.TEXT,
                    ScalarKind.TEXT.template,
                    Text::class,
                    com.typewritermc.configuration.TextExpressionsFactory,
                ) { nested -> textField(nested) },
        ),
    )

@Suppress("UNCHECKED_CAST")
private fun nullableIntegerField(scope: ConfigurationCollectionScope): NullableField<Int, Integer<Int>> =
    scope.field(
        RelativeFieldPattern.root,
        RepresentationKind.INTEGER,
        INT.nullable(),
        NullableField::class as KClass<NullableField<Int, Integer<Int>>>,
        mapOf(
            skirout.editor.v1.type_catalog.FieldPatternSegment.VALUES to
                com.typewritermc.configuration.NestedConfigurationScope(
                    RepresentationKind.INTEGER,
                    INT,
                    Integer::class,
                    com.typewritermc.configuration.NumberExpressionsFactory,
                ) { nested -> integerField(nested) },
        ),
    )
