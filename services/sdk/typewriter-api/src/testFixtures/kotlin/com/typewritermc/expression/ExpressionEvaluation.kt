package com.typewritermc.expression

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.root
import com.typewritermc.expression.operations.entryValue
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/**
 * What the portable evaluator gives for [expression] when each named input binding holds the given value, or is missing
 * when the value is null; every read of an input is recorded in [reads] when given.
 */
fun evaluate(
    expression: ExpressionNode,
    vararg inputs: Pair<String, DataValue?>,
    reads: MutableList<ValueLocation>? = null,
): Availability<DataValue> {
    val values = inputs.toMap()
    val reader =
        ExpressionValueReader { location ->
            reads?.add(location)
            val root = values[location.resource.value] ?: return@ExpressionValueReader Availability.Unavailable(listOf(location))
            when (val selected = root.locate(location.path)) {
                is LocatedPortableValue.Value -> Availability.Available(selected.value)
                is LocatedPortableValue.Row -> Availability.Available(entryValue(selected.row.key, selected.row.value))
                else -> Availability.Unavailable(listOf(location))
            }
        }
    val bindings =
        values.keys.associate {
            ExpressionBindingId(value = it) to
                ValueLocation(resource = ResourceId(value = it), path = ValuePath.root)
        }
    return with(FixtureReads) {
        DefaultExpressionEvaluator(reader, testPortableTypes()).evaluate(expression, ExpressionBindings(bindings), EVALUATION_BUDGET)
    }
}

/** What the portable evaluator gives for this expression with the given inputs bound. */
fun Expr<*, *>.evaluate(vararg inputs: Pair<String, DataValue?>): Availability<DataValue> = evaluate(toNode(), *inputs)

/** A list of integers whose items are keyed by position. */
fun integerList(vararg values: Int): DataValue =
    DataValue.listValue(
        values.mapIndexed {
            index,
            value,
            ->
            ListItem(id = ItemId(value = "item:$index"), value = DataValue.integer(value.toLong()))
        },
    )

/** The integers of a list value, nested lists as nested Kotlin lists. */
fun DataValue.integers(): List<Any> =
    (this as DataValue.ListValueWrapper).value.items.map { item ->
        when (val value = item.value) {
            is DataValue.ListValueWrapper -> value.integers()
            is DataValue.IntegerWrapper -> value.value.toInt()
            else -> error("Expected an integer or a list, found $value.")
        }
    }

private val EVALUATION_BUDGET = EvaluationBudget(maxSteps = 1000, maxCollectionItems = 1000)
