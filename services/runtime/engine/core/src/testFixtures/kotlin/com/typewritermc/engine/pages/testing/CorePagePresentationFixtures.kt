package com.typewritermc.engine.pages.testing

import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.PathSegment

/** The instance of a core page provider class: its `INSTANCE` field when it has one, otherwise a new instance. */
fun corePageProviderInstance(name: String): Any {
    val type = Class.forName(name)
    return type.fields.singleOrNull { it.name == "INSTANCE" }?.get(null) ?: type.getConstructor().newInstance()
}

/** The field name placeholder of the slot that presents every field not placed by the page or entry. */
const val REMAINING_FIELDS = "remaining fields"

/** The element of [this] and every element nested in its column and row children, in reading order. */
fun PresentationNode.flattened(): List<PresentationElement> {
    val element = element ?: return emptyList()
    val axis =
        when (val children = (element as? PresentationElement.ChildrenWrapper)?.value) {
            is ChildrenElement.ColumnWrapper -> children.value.children
            is ChildrenElement.RowWrapper -> children.value.children
            else -> emptyList()
        }
    val nodes =
        axis.mapNotNull { child ->
            when (child) {
                is AxisChild.FixedWrapper -> child.value
                is AxisChild.FlexibleWrapper -> child.value.child
                else -> null
            }
        }
    return listOf(element) + nodes.flatMap { it.flattened() }
}

/** The default presentation of this element, or null when the element is not a default presentation slot. */
val PresentationElement.defaultPresentation get() = (this as? PresentationElement.DefaultPresentationWrapper)?.value

/** True for the elements that present fields: a default presentation slot or the slot for the remaining fields. */
val PresentationElement.presentsFields
    get() = defaultPresentation != null || this is PresentationElement.RemainingFieldsWrapper

/** The field names an element edits, or [REMAINING_FIELDS] for the slot that presents every field not placed. */
val PresentationElement.fieldPaths: List<String>
    get() =
        defaultPresentation?.control?.binding?.path?.segments?.map { segment ->
            (segment as PathSegment.FieldWrapper).value.name
        } ?: listOf(REMAINING_FIELDS)
