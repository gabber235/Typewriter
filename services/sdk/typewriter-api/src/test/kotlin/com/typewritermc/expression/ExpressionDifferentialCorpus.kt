package com.typewritermc.expression

import build.skir.JsonFlavor
import com.typewritermc.authoring.Availability
import com.typewritermc.types.integer
import io.kotest.property.Arb
import io.kotest.property.RandomSource
import io.kotest.property.arbitrary.Codepoint
import io.kotest.property.arbitrary.arbitrary
import io.kotest.property.arbitrary.boolean
import io.kotest.property.arbitrary.element
import io.kotest.property.arbitrary.long
import io.kotest.property.arbitrary.map
import io.kotest.property.arbitrary.string
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import skirout.editor.v1.expression.CallExpression
import skirout.editor.v1.expression.ConditionalExpression
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.LogicalExpression
import skirout.editor.v1.expression.OperationId
import skirout.editor.v1.type_catalog.DataValue
import kotlinx.serialization.json.Json as KotlinJson

/*
 * The expression differential corpus: closed, well typed expressions over integers, booleans and text, generated from a
 * fixed seed, each with the outcome the Kotlin evaluator gives. Other hosts evaluate the same cases and must agree; a
 * disagreement becomes a hand written case in skir-src/editor/v1/fixtures/operations. The corpus is build output that
 * the `writeSdkFixtures` Gradle task writes in the operation fixture format, so a fixture runner reads it unchanged.
 */

/** Fixed, so every run writes and checks the same cases; change it only on purpose. */
internal const val CORPUS_SEED = 2_026_102_6L
internal const val CORPUS_SIZE = 2000
private const val CORPUS_DEPTH = 5

/** The budget the operation fixture runners use when a case names none. */
internal val CORPUS_BUDGET = EvaluationBudget(maxSteps = 1000, maxCollectionItems = 1000)

/** One generated expression and the outcome the Kotlin evaluator gives it. */
internal data class CorpusCase(
    val id: String,
    val expression: ExpressionNode,
    val outcome: Availability<DataValue>,
)

/** The value kinds the generator composes. */
internal enum class CorpusKind { INTEGER, BOOLEAN, TEXT }

/** The [CORPUS_SIZE] cases of the corpus, the same in every run. */
internal fun expressionCorpus(): List<CorpusCase> {
    val evaluator = DefaultExpressionEvaluator({ error("A closed expression reads nothing.") }, testPortableTypes())
    return Arb
        .closedExpression(CORPUS_DEPTH)
        .samples(RandomSource.seeded(CORPUS_SEED))
        .take(CORPUS_SIZE)
        .mapIndexed { index, sample ->
            val outcome = with(FixtureReads) { evaluator.evaluate(sample.value, ExpressionBindings(emptyMap()), CORPUS_BUDGET) }
            CorpusCase("corpus_%04d".format(index), sample.value, outcome)
        }.toList()
}

/** The corpus as an operation fixture document: `{"cases": [{id, expression, expected}]}`. */
internal fun renderExpressionCorpus(cases: List<CorpusCase> = expressionCorpus()): String {
    val document =
        buildJsonObject {
            put(
                "cases",
                buildJsonArray {
                    cases.forEach { case ->
                        add(
                            buildJsonObject {
                                put("id", case.id)
                                put(
                                    "expression",
                                    KotlinJson.parseToJsonElement(
                                        ExpressionNode.serializer.toJsonCode(case.expression, JsonFlavor.READABLE),
                                    ),
                                )
                                put("expected", case.outcome.expected())
                            },
                        )
                    }
                },
            )
        }
    return KotlinJson.encodeToString(JsonElement.serializer(), document) + "\n"
}

/** A closed expression of a random kind, at most [depth] calls deep. */
internal fun Arb.Companion.closedExpression(depth: Int): Arb<ExpressionNode> =
    arbitrary { expression(Arb.element(CorpusKind.entries).bind(), depth).bind() }

/** An expression of [kind]: a literal, or with [depth] left an operation whose arguments have the kinds it requires. */
internal fun expression(
    kind: CorpusKind,
    depth: Int,
): Arb<ExpressionNode> =
    arbitrary { random ->
        val composites = composites(kind)
        val pick = if (depth == 0) 0 else random.random.nextInt(composites.size + 1)
        if (pick == 0) literal(kind).bind() else composites[pick - 1](depth - 1).bind()
    }

private fun literal(kind: CorpusKind): Arb<ExpressionNode> =
    when (kind) {
        CorpusKind.INTEGER -> arbitrary { ExpressionNode.LiteralWrapper(DataValue.integer(Arb.long(-1000L..1000L).bind().toBigInteger())) }
        CorpusKind.BOOLEAN -> arbitrary { ExpressionNode.LiteralWrapper(DataValue.BooleanWrapper(Arb.boolean().bind())) }
        CorpusKind.TEXT -> arbitrary { ExpressionNode.LiteralWrapper(DataValue.StringValueWrapper(Arb.string(0..6, TEXT_ALPHABET).bind())) }
    }

/** Text from a small alphabet with case pairs, spaces, a combining mark and a character outside the basic plane. */
private val TEXT_ALPHABET: Arb<Codepoint> =
    Arb.element("aB ßée\u0301İ😀z".codePoints().toArray().distinct()).map(::Codepoint)

private fun composites(kind: CorpusKind): List<(Int) -> Arb<ExpressionNode>> =
    when (kind) {
        CorpusKind.INTEGER -> {
            listOf(
                { depth -> call("number.add", depth, CorpusKind.INTEGER, CorpusKind.INTEGER) },
                { depth -> call("number.subtract", depth, CorpusKind.INTEGER, CorpusKind.INTEGER) },
                { depth -> call("number.multiply", depth, CorpusKind.INTEGER, CorpusKind.INTEGER) },
                { depth -> call("number.remainder", depth, CorpusKind.INTEGER, CorpusKind.INTEGER) },
                { depth -> call("text.length", depth, CorpusKind.TEXT) },
                { depth -> conditional(CorpusKind.INTEGER, depth) },
            )
        }

        CorpusKind.BOOLEAN -> {
            listOf(
                { depth -> logical(depth, and = true) },
                { depth -> logical(depth, and = false) },
                { depth -> call("boolean.not", depth, CorpusKind.BOOLEAN) },
                { depth -> call("value.equals", depth, CorpusKind.INTEGER, CorpusKind.INTEGER) },
                { depth -> call("value.equals", depth, CorpusKind.TEXT, CorpusKind.TEXT) },
                { depth -> conditional(CorpusKind.BOOLEAN, depth) },
            )
        }

        CorpusKind.TEXT -> {
            listOf(
                { depth -> call("text.upper", depth, CorpusKind.TEXT) },
                { depth -> call("text.lower", depth, CorpusKind.TEXT) },
                { depth -> call("text.trim_start", depth, CorpusKind.TEXT) },
                { depth -> call("text.fold_case", depth, CorpusKind.TEXT) },
                { depth -> call("value.to_text", depth, CorpusKind.INTEGER) },
                { depth -> conditional(CorpusKind.TEXT, depth) },
            )
        }
    }

private fun call(
    operation: String,
    depth: Int,
    vararg arguments: CorpusKind,
): Arb<ExpressionNode> =
    arbitrary {
        ExpressionNode.CallWrapper(
            CallExpression(
                operation = OperationId(value = operation),
                typeArguments = emptyList(),
                arguments = arguments.map { expression(it, depth).bind() },
            ),
        )
    }

private fun logical(
    depth: Int,
    and: Boolean,
): Arb<ExpressionNode> =
    arbitrary {
        val operands =
            LogicalExpression(left = expression(CorpusKind.BOOLEAN, depth).bind(), right = expression(CorpusKind.BOOLEAN, depth).bind())
        if (and) ExpressionNode.AndWrapper(operands) else ExpressionNode.OrWrapper(operands)
    }

private fun conditional(
    kind: CorpusKind,
    depth: Int,
): Arb<ExpressionNode> =
    arbitrary {
        ExpressionNode.ConditionalWrapper(
            ConditionalExpression(
                test = expression(CorpusKind.BOOLEAN, depth).bind(),
                then = expression(kind, depth).bind(),
                otherwise = expression(kind, depth).bind(),
            ),
        )
    }

/** The `expected` object of the operation fixture format for this outcome. */
private fun Availability<DataValue>.expected(): JsonElement =
    buildJsonObject {
        when (val outcome = this@expected) {
            is Availability.Available -> put("available", outcome.value.compact())
            is Availability.Failed -> put("failed", outcome.diagnostic.failure.value)
            is Availability.Unavailable -> error("A closed expression is never unavailable.")
        }
        put("reads", buildJsonArray { })
    }

/** The compact value of the operation fixture format, for the kinds the corpus produces. */
private fun DataValue.compact(): JsonElement =
    buildJsonObject {
        when (val value = this@compact) {
            is DataValue.BooleanWrapper -> put("boolean", value.value)
            is DataValue.IntegerWrapper -> put("integer", JsonPrimitive(value.value))
            is DataValue.StringValueWrapper -> put("string", value.value)
            else -> error("The corpus produces no $value.")
        }
    }
