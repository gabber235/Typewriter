package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.TypewriterContent
import com.typewritermc.types.Ref

/**
 * Conformance fixture proving that an element can reference the marker type declared by a concrete Page. Its
 * payload exercises typed Page resolution and reference projection.
 */
@TypewriterContent(
    id = "019d3a87000270008000000000000002",
    revision = 1,
    name = "Synthetic Page Reference",
    description = "Verifies concrete Page references",
    icon = "material-symbols:link",
    color = "#536DFE",
)
data class SyntheticPageReferenceEntry(
    override val name: String,
    override val placement: GraphPlacement,
    val page: Ref<SyntheticPage>,
) : ConformanceEntry
