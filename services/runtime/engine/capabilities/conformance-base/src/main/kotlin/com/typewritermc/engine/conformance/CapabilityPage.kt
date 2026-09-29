package com.typewritermc.engine.conformance

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.elements.Element
import com.typewritermc.library.Book
import com.typewritermc.library.BookPages
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.types.ToMany
import com.typewritermc.types.ToOne
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

/**
 * Defines the element role exported by the conformance capability.
 *
 * Its generated page demonstrates that capability supplied abstract roles remain discoverable through engine
 * composition.
 */
interface CapabilityElement : Element {
    override val placement: GraphPlacement
}

/** Concrete Page accepting the capability supplied element role. */
@TypewriterType(id = "019d3a87002070008000000000000020")
@TypewriterDisplay(name = "Capability", icon = "material-symbols:extension", color = "#607D8B")
@TypewriterPage.Graph(GraphDirection.LEFT_TO_RIGHT)
data class CapabilityPage(
    override val book: ToOne<BookPages, Book>,
    override val name: String = "",
    override val chapter: ChapterPath = ChapterPath.Root,
    override val priority: Int = 0,
    override val elements: ToMany<PageElements, CapabilityElement> = ToMany.empty(),
) : Page
