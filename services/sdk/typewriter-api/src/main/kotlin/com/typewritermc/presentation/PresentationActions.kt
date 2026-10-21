package com.typewritermc.presentation

import com.typewritermc.authoring.TypedPath
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.Handled
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.action.CreateFieldValue
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate

/** Owns completion for one configured scope before its parent captures child nodes. */
internal class ControlScopeSession<S>(
    val receiver: S,
    private val finish: (MutableList<PresentationNode>) -> Unit,
) {
    private var finished = false

    fun finishInto(target: MutableList<PresentationNode>) {
        check(!finished) { "The scoped configuration has already finished." }
        finish(target)
        finished = true
    }
}

open class PresentationInput<Value, Scope> internal constructor(
    val binding: BindingRef,
    internal val session: ControlScopeSession<Scope>,
    internal val expected: TypeTemplate? = null,
    internal val rebind: ((BindingRef, MutableList<PresentationNode>) -> ControlScopeSession<Scope>)? = null,
) {
    val scope: Scope get() = session.receiver
}

class EditablePresentationInput<Value, Scope> internal constructor(
    binding: BindingRef,
    session: ControlScopeSession<Scope>,
    internal val actions: PresentationActionFactory,
) : PresentationInput<Value, Scope>(binding, session)

data class PresentationParameter<Value>(
    val binding: ExpressionBindingId,
)

fun <Value> presentationParameter(name: String): PresentationParameter<Value> {
    require(name.isNotBlank()) { "Presentation parameter names must not be blank." }
    require(!name.startsWith("context:")) { "Presentation parameters cannot shadow caller inputs." }
    return PresentationParameter(ExpressionBindingId(name))
}

interface PresentationActionFactory {
    fun set(
        binding: BindingRef,
        value: skirout.editor.v1.expression.ExpressionNode,
    ): EditorAction

    fun insertAfter(
        binding: BindingRef,
        item: ItemId?,
        value: skirout.editor.v1.expression.ExpressionNode,
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
        key: skirout.editor.v1.expression.ExpressionNode,
        value: skirout.editor.v1.expression.ExpressionNode,
    ): EditorAction

    fun updateRow(
        binding: BindingRef,
        row: ItemId,
        key: skirout.editor.v1.expression.ExpressionNode,
        value: skirout.editor.v1.expression.ExpressionNode,
    ): EditorAction

    fun removeRow(
        binding: BindingRef,
        row: ItemId,
    ): EditorAction

    fun chooseForm(
        binding: BindingRef,
        type: NamedTypeUse,
    ): EditorAction
}

fun <V> EditablePresentationInput<V, *>.set(value: Expr<V, Handled>): EditorAction = actions.set(binding, value.toNode())

fun <Item> EditablePresentationInput<List<Item>, *>.insertAfter(
    item: ItemId?,
    value: Expr<Item, Handled>,
): EditorAction = actions.insertAfter(binding, item, value.toNode())

fun <Item> EditablePresentationInput<List<Item>, *>.append(value: Expr<Item, Handled>): EditorAction =
    actions.insertAfter(binding, null, value.toNode())

fun EditablePresentationInput<*, *>.removeItem(item: ItemId): EditorAction = actions.removeItem(binding, item)

fun EditablePresentationInput<*, *>.duplicateItem(item: ItemId): EditorAction = actions.duplicateItem(binding, item)

fun EditablePresentationInput<*, *>.moveItem(
    item: ItemId,
    after: ItemId?,
): EditorAction = actions.moveItem(binding, item, after)

fun <K, V> EditablePresentationInput<Map<K, V>, *>.insertRow(
    key: Expr<K, Handled>,
    value: Expr<V, Handled>,
): EditorAction = actions.insertRow(binding, key.toNode(), value.toNode())

fun <K, V> EditablePresentationInput<Map<K, V>, *>.updateRow(
    row: ItemId,
    key: Expr<K, Handled>,
    value: Expr<V, Handled>,
): EditorAction = actions.updateRow(binding, row, key.toNode(), value.toNode())

fun EditablePresentationInput<*, *>.removeRow(row: ItemId): EditorAction = actions.removeRow(binding, row)

fun <V> EditablePresentationInput<V, *>.chooseForm(type: AppliedPresentation<out V>): EditorAction = actions.chooseForm(binding, type.type)

/** Preset fields of a resource that a create action makes. */
@TypewriterDsl
class CreateResourceScope internal constructor() {
    internal val fields = mutableListOf<CreateFieldValue>()

    /** Presets the field at this path of the created resource to [value]. */
    operator fun <V> TypedPath<*, V>.invoke(value: Expr<V, Handled>) {
        val wirePath = SkirAuthoringValueCodec.encode(path).getOrThrow()
        require(fields.none { it.path == wirePath }) { "A create action presets each field once." }
        fields += CreateFieldValue(path = wirePath, value = value.toNode())
    }
}

/**
 * Creates a resource of [type] and links it into [owner], a link field of the presentation subject on the owner side
 * of an ownership relation, such as `BookFields.pages` in a Book presentation. Without an owner the host chooses one,
 * for example the single instance of a realm section. [presets] fill fields of the created resource; the presentation
 * check rejects an owner that is not an owning link field of the subject and presets that are not fields of [type].
 */
fun createResource(
    type: TypeDefinitionId,
    owner: TypedPath<*, *>? = null,
    presets: CreateResourceScope.() -> Unit = {},
): EditorAction {
    val scope = CreateResourceScope().apply(presets)
    return EditorAction.createCreate(
        type = type,
        owner =
            owner?.let {
                BindingRef(
                    path = SkirAuthoringValueCodec.encode(it.path).getOrThrow(),
                    bindingId = CONFIGURED_VALUE.wire(),
                )
            },
        fields = scope.fields.toList(),
    )
}
