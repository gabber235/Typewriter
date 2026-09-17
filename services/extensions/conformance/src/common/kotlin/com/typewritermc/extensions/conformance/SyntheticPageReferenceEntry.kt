package com.typewritermc.extensions.conformance

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.Entry
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.types.Ref

/**
 * Conformance fixture proving that an element can reference the marker type generated for a page declaration. Its
 * payload exercises page kind resolution and reference projection.
 */
@TypewriterElement(
    id = "019d3a87000270008000000000000002",
    revision = 2,
    name = "Synthetic Page Reference",
    description = "Verifies generated page kind references",
    icon = "material-symbols:link",
    color = "#536DFE",
)
data class SyntheticPageReferenceEntry(
    override val id: ElementInstanceId,
    override val name: String,
    val page: Ref<SyntheticPageKind>,
) : Entry
