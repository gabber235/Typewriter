package com.typewritermc.presentation

import com.typewritermc.authoring.TypedPath
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.template
import com.typewritermc.types.use
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.action.LocalEditorAction
import skirout.editor.v1.action.ResourceNavigationMode
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValuePath

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

/** Reads the value this input binds, which may be missing. */
internal fun <Value> PresentationInput<Value, *>.read(): Expr<Value, com.typewritermc.expression.MayBeMissing> =
    com.typewritermc.expression.inputExpression(binding.bindingId, binding.path)

class EditablePresentationInput<Value, Scope> internal constructor(
    binding: BindingRef,
    session: ControlScopeSession<Scope>,
) : PresentationInput<Value, Scope>(binding, session)

data class PresentationParameter<Value>(
    val binding: ExpressionBindingId,
)

fun <Value> presentationParameter(name: String): PresentationParameter<Value> {
    require(name.isNotBlank()) { "Presentation parameter names must not be blank." }
    require(!name.startsWith("context:")) { "Presentation parameters cannot shadow caller inputs." }
    return PresentationParameter(ExpressionBindingId(value = name))
}

/**
 * An editor action an interaction runs. Its expressions are lowered and checked against the slot types of the action
 * when the interaction holding it is built, so an action cannot carry an ill typed value into the wire.
 */
class PresentationAction internal constructor(
    internal val lower: (PresentationBuildState) -> EditorAction,
)

/** The caller supplied values actions may read: the resource acted for and the selected resources. */
object ActionContext {
    /** The resource the action acts for. */
    val subject: Expr<ResourceId, Handled> = com.typewritermc.expression.inputExpression(ACTION_SUBJECT)

    /** The resources selected where the action runs. */
    val selection: Expr<List<ResourceId>, Handled> = com.typewritermc.expression.inputExpression(ACTION_SELECTION)
}

/** An authoring capability with the type of its initial input, so the input an action passes is checked. */
interface AuthoringCapability<Input> {
    val id: CapabilityId

    /** The type of the initial input; a capability without input declares the unit type. */
    val input: TypeTemplate
}

/** Opens, reveals or edits the resource [resource] evaluates to, which may read [ActionContext]. */
fun navigate(
    resource: Expr<ResourceId, Handled>,
    mode: ResourceNavigationMode = ResourceNavigationMode.OPEN,
): PresentationAction =
    PresentationAction { state ->
        state.actionContext()
        EditorAction.createNavigate(resource = state.lower(resource, ResourceIdDefinition.id.template()), mode = mode)
    }

/** Enters authoring preparation of [capability] for [targets], the selection by default, starting from [input]. */
fun <Input> authoring(
    capability: AuthoringCapability<Input>,
    input: Expr<Input, Handled>,
    targets: Expr<List<ResourceId>, Handled> = ActionContext.selection,
): PresentationAction = authoringAction(capability, input, targets)

/** Enters authoring preparation of [capability], which takes no input, for [targets], the selection by default. */
fun authoring(
    capability: AuthoringCapability<Unit>,
    targets: Expr<List<ResourceId>, Handled> = ActionContext.selection,
): PresentationAction = authoringAction(capability, null, targets)

private fun authoringAction(
    capability: AuthoringCapability<*>,
    input: Expr<*, Handled>?,
    targets: Expr<List<ResourceId>, Handled>,
): PresentationAction =
    PresentationAction { state ->
        state.actionContext()
        state.capability(capability.id)
        EditorAction.createAuthoring(
            capability = capability.id,
            targets = state.lower(targets, StandardTypes.list.template(listOf(ResourceIdDefinition.id.template()))),
            initialInput = input?.let { state.lower(it, capability.input) },
        )
    }

/** Replaces the value of this input with [value]. */
fun <V> EditablePresentationInput<V, *>.set(value: Expr<V, Handled>): PresentationAction =
    PresentationAction { state ->
        EditorAction.LocalWrapper(
            LocalEditorAction.createSetValue(target = binding, value = state.lower(value, state.typeOf(binding))),
        )
    }

/** Inserts [value] after the item [item] of this list, or first when [item] is null. */
fun <Item> EditablePresentationInput<List<Item>, *>.insertAfter(
    item: ItemId?,
    value: Expr<Item, Handled>,
): PresentationAction =
    PresentationAction { state ->
        EditorAction.LocalWrapper(
            LocalEditorAction.createInsertListItem(target = binding, after = item, value = state.lower(value, state.itemOf(binding))),
        )
    }

/** Appends [value] to this list. */
fun <Item> EditablePresentationInput<List<Item>, *>.append(value: Expr<Item, Handled>): PresentationAction =
    PresentationAction { state ->
        EditorAction.LocalWrapper(
            LocalEditorAction.createAppendListItem(target = binding, value = state.lower(value, state.itemOf(binding))),
        )
    }

fun EditablePresentationInput<*, *>.removeItem(item: ItemId): PresentationAction =
    local { LocalEditorAction.createRemoveListItem(target = binding, item = item) }

fun EditablePresentationInput<*, *>.duplicateItem(item: ItemId): PresentationAction =
    local { LocalEditorAction.createDuplicateListItem(target = binding, item = item) }

fun EditablePresentationInput<*, *>.moveItem(
    item: ItemId,
    after: ItemId?,
): PresentationAction = local { LocalEditorAction.createMoveListItem(target = binding, item = item, after = after) }

/** Inserts a row of [key] and [value] into this map. */
fun <K, V> EditablePresentationInput<Map<K, V>, *>.insertRow(
    key: Expr<K, Handled>,
    value: Expr<V, Handled>,
): PresentationAction =
    PresentationAction { state ->
        val map = state.type.rebind(state.typeOf(binding))
        EditorAction.LocalWrapper(
            LocalEditorAction.createInsertMapRow(
                target = binding,
                key = state.lower(key, map.nested(NestedPresentationSlot.Keys).type.type),
                value = state.lower(value, map.nested(NestedPresentationSlot.Values).type.type),
            ),
        )
    }

/** Replaces the key and value of the row [row] of this map. */
fun <K, V> EditablePresentationInput<Map<K, V>, *>.updateRow(
    row: ItemId,
    key: Expr<K, Handled>,
    value: Expr<V, Handled>,
): PresentationAction =
    PresentationAction { state ->
        val map = state.type.rebind(state.typeOf(binding))
        EditorAction.LocalWrapper(
            LocalEditorAction.createUpdateMapRow(
                target = binding,
                row = row,
                key = state.lower(key, map.nested(NestedPresentationSlot.Keys).type.type),
                value = state.lower(value, map.nested(NestedPresentationSlot.Values).type.type),
            ),
        )
    }

fun EditablePresentationInput<*, *>.removeRow(row: ItemId): PresentationAction =
    local { LocalEditorAction.createRemoveMapRow(target = binding, row = row) }

fun <V> EditablePresentationInput<V, *>.chooseForm(type: AppliedPresentation<out V>): PresentationAction =
    local { LocalEditorAction.createChooseForm(target = binding, type = type.type.use) }

private fun local(action: () -> LocalEditorAction): PresentationAction = PresentationAction { EditorAction.LocalWrapper(action()) }

private fun PresentationBuildState.itemOf(binding: BindingRef): TypeTemplate =
    requireNotNull(itemType(typeOf(binding))) { "List actions target a list." }

/** Preset fields of a resource that a create action makes. */
@TypewriterDsl
class CreateResourceScope internal constructor() {
    internal val fields = linkedMapOf<ValuePath, Expr<*, *>>()

    /** Presets the field at this path of the created resource to [value]; a missing value keeps the creation default. */
    operator fun <V> TypedPath<*, V>.invoke(value: Expr<V, com.typewritermc.expression.MissingPolicy>) {
        val wirePath = path
        require(wirePath !in fields) { "A create action presets each field once." }
        fields[wirePath] = value
    }
}

/**
 * Creates a resource of [type] and links it into [owner], a link field of the presentation subject on the owner side
 * of an ownership relation, such as `BookFields.pages` in a Book presentation. Without an owner the host chooses one,
 * for example the single instance of a realm section. [presets] fill fields of the created resource; building rejects
 * an owner that is not an owning link field of the subject and presets that are not fields of [type].
 */
fun createResource(
    type: TypeDefinitionId,
    owner: TypedPath<*, *>? = null,
    presets: CreateResourceScope.() -> Unit = {},
): PresentationAction {
    val scope = CreateResourceScope().apply(presets)
    return PresentationAction { state ->
        state.createResource(
            created = type,
            owner = owner?.let { BindingRef(path = it.path, bindingId = CONFIGURED_VALUE) },
            presets = scope.fields.toMap(),
        )
    }
}
