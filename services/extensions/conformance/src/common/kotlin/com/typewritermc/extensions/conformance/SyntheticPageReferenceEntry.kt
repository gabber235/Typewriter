package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

/**
 * Conformance fixture proving that an element can reference the marker type declared by a concrete Page. Its
 * payload exercises typed Page resolution and reference projection.
 */
@TypewriterType(id = "019d3a87000270008000000000000002", revision = 1)
@TypewriterDisplay(
    name = "Synthetic Page Reference",
    description = "Verifies concrete Page references",
    icon = "material-symbols:link",
    color = "#536DFE",
)
data class SyntheticPageReferenceEntry(
    override val name: String,
    override val placement: GraphPlacement,
    val page: Ref<SyntheticPageReferences.Entry, SyntheticPage>,
) : ConformanceEntry

@ReferenceContract(SYNTHETIC_PAGE_REFERENCES_RELATION_ID)
interface SyntheticPageReferencesContract {
    interface Entry : Many<ConformanceEntry>

    interface Page : One<com.typewritermc.library.Page>
}

const val SYNTHETIC_PAGE_REFERENCES_RELATION_ID = "019d3a87003470008000000000000034"
