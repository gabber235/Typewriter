package com.typewritermc.presentation

import com.typewritermc.authoring.ItemId
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.types.TypeTemplate
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.PresentationNode

open class PresentationInput<Value, Scope> internal constructor(
    val binding: BindingRef,
    val scope: Scope,
    internal val expected: TypeTemplate? = null,
    internal val rebind: ((BindingRef, MutableList<PresentationNode>) -> Scope)? = null,
)

class EditablePresentationInput<Value, Scope> internal constructor(
    binding: BindingRef,
    scope: Scope,
    internal val actions: PresentationActionFactory,
) : PresentationInput<Value, Scope>(binding, scope)

data class PresentationParameter<Value>(
    val binding: ExpressionBindingId,
)

fun <Value> presentationParameter(name: String): PresentationParameter<Value> {
    require(name.isNotBlank()) { "Presentation parameter names must not be blank." }
    return PresentationParameter(ExpressionBindingId(name))
}

interface PresentationActionFactory {
    fun set(
        binding: BindingRef,
        value: com.typewritermc.presentation.ExpressionNode,
    ): EditorAction

    fun insertAfter(
        binding: BindingRef,
        item: ItemId?,
        value: com.typewritermc.presentation.ExpressionNode,
    ): EditorAction

    fun removeItem(
        binding: BindingRef,
        item: ItemId,
    ): EditorAction

    fun duplicateItem(
        binding: BindingRef,
        item: ItemId,
    ): EditorAction

    fun moveItem(
        binding: BindingRef,
        item: ItemId,
        after: ItemId?,
    ): EditorAction

    fun insertRow(
        binding: BindingRef,
        key: com.typewritermc.presentation.ExpressionNode,
        value: com.typewritermc.presentation.ExpressionNode,
    ): EditorAction

    fun updateRow(
        binding: BindingRef,
        row: ItemId,
        key: com.typewritermc.presentation.ExpressionNode,
        value: com.typewritermc.presentation.ExpressionNode,
    ): EditorAction

    fun removeRow(
        binding: BindingRef,
        row: ItemId,
    ): EditorAction

    fun chooseForm(
        binding: BindingRef,
        type: com.typewritermc.types.TypeUse.Named,
    ): EditorAction
}

fun <V> EditablePresentationInput<V, *>.set(value: Expr<V, Handled>): EditorAction = actions.set(binding, value.node)

fun <Item> EditablePresentationInput<List<Item>, *>.insertAfter(
    item: ItemId?,
    value: Expr<Item, Handled>,
): EditorAction = actions.insertAfter(binding, item, value.node)

fun <Item> EditablePresentationInput<List<Item>, *>.append(value: Expr<Item, Handled>): EditorAction =
    actions.insertAfter(binding, null, value.node)

fun EditablePresentationInput<*, *>.removeItem(item: ItemId): EditorAction = actions.removeItem(binding, item)

fun EditablePresentationInput<*, *>.duplicateItem(item: ItemId): EditorAction = actions.duplicateItem(binding, item)

fun EditablePresentationInput<*, *>.moveItem(
    item: ItemId,
    after: ItemId?,
): EditorAction = actions.moveItem(binding, item, after)

fun <K, V> EditablePresentationInput<Map<K, V>, *>.insertRow(
    key: Expr<K, Handled>,
    value: Expr<V, Handled>,
): EditorAction = actions.insertRow(binding, key.node, value.node)

fun <K, V> EditablePresentationInput<Map<K, V>, *>.updateRow(
    row: ItemId,
    key: Expr<K, Handled>,
    value: Expr<V, Handled>,
): EditorAction = actions.updateRow(binding, row, key.node, value.node)

fun EditablePresentationInput<*, *>.removeRow(row: ItemId): EditorAction = actions.removeRow(binding, row)

fun <V> EditablePresentationInput<V, *>.chooseForm(type: AppliedPresentation<out V>): EditorAction = actions.chooseForm(binding, type.type)
