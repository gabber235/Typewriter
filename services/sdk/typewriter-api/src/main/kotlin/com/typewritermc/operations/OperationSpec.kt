package com.typewritermc.operations

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypedPath
import com.typewritermc.discovery.GeneratedContract
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.presentation.PresentationReference
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId

/**
 * An operation on every resource. Codegen emits the same contract per resource type, `XOperation<I>`, whose spec
 * reads drafts of that type; generic resources keep their native and draft type parameters before [I]:
 *
 * ```kotlin
 * object ResetReward : VariableOperation<CoinReward, CoinRewardDraft, Unit> {
 *     override fun VariableOperationSpec<CoinReward, CoinRewardDraft, Unit>.declare(): PreparedOperation {
 *         appearance { icon("mdi:restore") }
 *         return prepare { drafts.forEach { it.setValue(CoinReward(0)) } }
 *     }
 * }
 * ```
 *
 * The object is the declaration: its fully qualified name is the operation identity, its name in sentence case the
 * default label, and [I] the input, which is [Unit] or a `@TypewriterType`. Applicability comes from the contract
 * type and from availability read in graph facts; there is no other opt out.
 */
@GeneratedContract(kind = GeneratedContract.Kind.Operation, target = Resource::class)
interface ResourceOperation<I> {
    fun ResourceOperationSpec<I>.declare(): PreparedOperation
}

/** The spec of an operation on every resource; its drafts are untyped resource drafts. */
interface ResourceOperationSpec<I> : OperationSpec<ResourceDraft, I>

@GeneratedSdkApi
class ResourceOperationSpecImpl<I>(
    spec: OperationSpec<ResourceDraft, I>,
) : ResourceOperationSpec<I>,
    OperationSpec<ResourceDraft, I> by spec

/** Finishes a declaration. Only [OperationSpec.prepare] creates one, so a declaration without preparation does not compile. */
class PreparedOperation internal constructor()

/**
 * Declares one operation. Required values are parameters and optional ones trailing blocks. Declaration runs once at
 * catalog assembly; the callbacks it registers run per invocation against the captured working graph.
 */
@TypewriterDsl
interface OperationSpec<D : ResourceDraft, I> {
    /** Menu, inspector and drop appearance. The label defaults to the object name in sentence case. */
    fun appearance(body: OperationAppearanceScope.() -> Unit)

    /** Asks before staging the prepared edit. */
    fun confirm(
        message: String,
        body: OperationConfirmScope.() -> Unit = {},
    )

    /** How input fields are offered by pickers and filled by drops. */
    fun input(body: OperationInputScope<D, I>.() -> Unit)

    /** Keyboard gestures that invoke the operation. */
    fun gestures(body: OperationGestureScope.() -> Unit)

    /** Restricts invocation to exactly one subject. */
    fun singleSubject()

    /**
     * Evaluates against the invocation's captured working graph; defaults to enabled. Keep it stateless and free of
     * effects: it runs again for later invocations, and generated draft setters require the edit context absent here.
     */
    fun availableWhen(body: OperationReadScope<D>.() -> OperationAvailability)

    /**
     * Builds tentative edits against the captured working graph without committing or performing external effects.
     * A retry after form input or a choice starts a fresh attempt. Use [OperationPreparation.identities] for new IDs.
     * The caller validates the complete batch, then stages the exact preview through its ordinary edit owner.
     */
    fun prepare(body: suspend OperationPrepareScope<D, I>.() -> Unit): PreparedOperation
}

@TypewriterDsl
interface OperationAppearanceScope {
    fun label(value: String)

    fun description(value: String)

    fun icon(value: String)

    /** Menu section and position. The destructive group implies the destructive tone. */
    fun group(
        value: OperationGroup,
        order: Int = 0,
    )

    /** Inspector presence: a button with an emphasis, or hidden (menus, shortcuts and drops only). */
    fun inspector(value: OperationInspector)
}

@TypewriterDsl
interface OperationConfirmScope {
    /** Defaults to the label. */
    fun title(value: String)

    /** Confirm button text; defaults to the label. */
    fun action(value: String)
}

@TypewriterDsl
interface OperationInputScope<D : ResourceDraft, I> {
    /** Replaces the form editors generate from the declared input fields. */
    fun form(presentation: PresentationReference)

    /**
     * Declares how pickers offer and drops fill this input field: `MoveToOwnerInputFields.destination { ... }`. The
     * path's owner may be a supertype application of [I], such as the star projection of a generic input.
     */
    operator fun <V> TypedPath<in I, V>.invoke(body: OperationFieldScope<D, V>.() -> Unit)
}

@TypewriterDsl
interface OperationFieldScope<D : ResourceDraft, V> {
    /**
     * Values pickers offer and drops accept, read from the subjects through graph facts. A resource identity field
     * with candidates gets a candidate search in generated forms. Reads are recorded as observations.
     */
    fun candidates(body: OperationReadScope<D>.() -> Sequence<V>)

    /** Fast check for one value; defaults to membership in [candidates]. */
    fun accepts(body: OperationReadScope<D>.(value: V) -> Boolean)
}

/**
 * A resource dropped onto another resource fills this field with the resource dropped onto. [hint] labels the drop
 * while hovering and defaults to the operation label. Catalog assembly requires [OperationFieldScope.candidates] in the
 * same field and rejects a second drop field in one operation.
 */
fun <D : ResourceDraft> OperationFieldScope<D, ResourceId>.fillOnDrop(hint: String? = null) {
    check(this is OperationFieldBuilder<*, *>) { "Drops are declared inside an operation input field." }
    fillOnDrop(hint)
}

@TypewriterDsl
interface OperationGestureScope {
    fun shortcut(value: OperationShortcut)
}
