package com.typewritermc.engine.conformance

import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageEditorDefinition
import com.typewritermc.pages.PageSpec
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.pages.page

/**
 * Defines the element role exported by the conformance capability.
 *
 * Its generated page demonstrates that capability supplied abstract roles remain discoverable through engine
 * composition.
 */
interface CapabilityElement : Element {
    override val id: ElementInstanceId
}

@TypewriterPage(id = "019d3a87002070008000000000000020", revision = 1)
fun capabilityPage(): PageSpec =
    page(
        editor = PageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT, listOf(CapabilityElement::class)),
        icon = "material-symbols:extension",
        color = "#607D8B",
    )
