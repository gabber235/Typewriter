package com.typewritermc.expression.shortcuts

import com.typewritermc.authoring.Availability
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.FixtureReads
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.input
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem

/** The binding the shortcut tests evaluate against. */
internal val SUBJECT = ExpressionBindingId(value = "subject")

/** The subject value of a shortcut test, typed for the shortcut under test. */
internal fun <T> subject(): Expr<T, MayBeMissing> = input(SUBJECT)

/** Evaluates [expression] with the real Kotlin evaluator, binding [subject] as an unlocated value. */
internal fun evaluate(
    expression: Expr<*, *>,
    subject: DataValue? = null,
): Availability<DataValue> = evaluate(expression.toNode(), subject)

/** Evaluates [node] with the real Kotlin evaluator, binding [subject] as an unlocated value. */
internal fun evaluate(
    node: ExpressionNode,
    subject: DataValue? = null,
): Availability<DataValue> =
    with(FixtureReads) {
        DefaultExpressionEvaluator(ExpressionValueReader { error("Shortcut tests bind unlocated values only.") }).evaluateScoped(
            node,
            ExpressionBindings(emptyMap()),
            subject?.let { mapOf(SUBJECT to it) } ?: emptyMap(),
            EvaluationBudget(maxSteps = 10_000, maxCollectionItems = 10_000),
        )
    }

internal fun available(value: Boolean): Availability<DataValue> = Availability.Available(DataValue.BooleanWrapper(value))

internal fun available(value: String): Availability<DataValue> = Availability.Available(DataValue.StringValueWrapper(value))

internal fun available(value: Long): Availability<DataValue> = Availability.Available(DataValue.integer(value))

internal fun text(value: String): DataValue = DataValue.StringValueWrapper(value)

internal fun number(value: Long): DataValue = DataValue.integer(value)

/** A list whose items have the identities [ids], or "0", "1", ... when omitted. */
internal fun list(
    vararg values: DataValue,
    ids: List<String> = values.indices.map(Int::toString),
): DataValue = DataValue.listValue(values.zip(ids) { value, id -> ListItem(id = ItemId(value = id), value = value) })

internal fun numbers(vararg values: Long): DataValue = list(*values.map(::number).toTypedArray())

internal fun texts(vararg values: String): DataValue = list(*values.map(::text).toTypedArray())
