package com.typewritermc.presentation

import com.typewritermc.discovery.GraphDirection
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.types.Resource

interface RecordControl<Fields : Layout> : Control {
    fun recordInput(fields: ControlConfiguration<Fields> = {})
}

interface ListControl<ItemScope> : Control {
    fun listInput(
        allowAdd: Boolean = true,
        allowRemove: Boolean = true,
        allowReorder: Boolean = true,
        items: ControlConfiguration<ItemScope> = {},
    )
}

interface ResourceLinksControl<R : Resource> : ListControl<LinkControl<R>> {
    fun graphPage(direction: GraphDirection)

    fun timelinePage()
}

interface SetControl<ItemScope> : Control {
    fun collectionInput(
        allowAdd: Boolean = true,
        allowRemove: Boolean = true,
        items: ControlConfiguration<ItemScope> = {},
    )
}

interface MapControl<KeyScope, ValueScope> : Control {
    fun mapInput(
        allowAdd: Boolean = true,
        allowRemove: Boolean = true,
        keys: ControlConfiguration<KeyScope> = {},
        values: ControlConfiguration<ValueScope> = {},
    )
}

interface NullableControl<ValueScope> : Control {
    fun nullableInput(value: ControlConfiguration<ValueScope> = {})
}

interface PolymorphicControl<V> : Control {
    fun polymorphicInput(configure: ConcreteForms<V>.() -> Unit = {})
}

interface ConcreteForms<V> {
    fun <Subtype : V> form(
        type: AppliedPresentation<Subtype>,
        label: Expr<String, Handled>? = null,
    )
}

interface LinkControl<R : Resource> : Control {
    fun linkInput(
        source: CollectionSource<*, com.typewritermc.types.ResourceId>? = null,
        policy: LinkCandidatePolicyId? = null,
        rejection: LinkRejectionDisplay = LinkRejectionDisplay.Hidden,
    )
}

interface LinkCollectionControl<R : Resource> : Control {
    fun linkInput(
        allowReorder: Boolean = false,
        source: CollectionSource<*, com.typewritermc.types.ResourceId>? = null,
        policy: LinkCandidatePolicyId? = null,
        rejection: LinkRejectionDisplay = LinkRejectionDisplay.Hidden,
    )
}

enum class LinkRejectionDisplay { Hidden, DisabledWithReason }

@JvmInline
value class LinkCandidatePolicyId(
    val value: String,
)

data class AppliedPresentation<V>(
    val type: com.typewritermc.types.TypeUse.Named,
    val reference: PresentationReference,
)
