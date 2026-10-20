package com.typewritermc.elements

import com.typewritermc.authoring.defaultLabel
import com.typewritermc.expression.color
import com.typewritermc.expression.display
import com.typewritermc.expression.icon
import com.typewritermc.expression.literal
import com.typewritermc.expression.name
import com.typewritermc.expression.neq
import com.typewritermc.expression.orElse
import com.typewritermc.expression.orIfBlank
import com.typewritermc.expression.trim
import com.typewritermc.library.LibraryContext
import com.typewritermc.library.fields
import com.typewritermc.library.pageLocation
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.icon
import com.typewritermc.presentation.resource
import com.typewritermc.presentation.resourceSearchResult
import com.typewritermc.presentation.searchDescription
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.PresentationRole

object ElementSdkProvider : ElementConfiguration {
    override fun ElementConfigurationScope.configure() {
        name {
            nonEmpty()
            singleLine()
        }
    }
}

/** Every element names itself; accent and icon stay those of its element type. */
object ElementNaming : ElementDisplay {
    override fun ElementDisplayScope.label() = name.orIfBlank(defaultLabel())
}

object ElementInspectorPresentation : ElementPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun ElementPresentationScope.present() {
        name {
            label("name")
            textInput { onComplete { value.trim() } }
        }
        remainingFields()
    }
}

object ElementSearchPresentation : ElementPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_PICKER_RESULT, PresentationRole.RESOURCE_SEARCH_RESULT)

    override fun ElementPresentationScope.present() {
        val element = subject.resource<Element>()
        val page = element.fields.page.resource
        val display = element.type.display
        val origin = context.read(LibraryContext.activeResource)
        val color = display.color.orElse(literal(Color(0xff9c64bdu)))
        resourceSearchResult(
            title = element.fields.name.orIfBlank("Unnamed element"),
            accent = color,
            kind = literal("element"),
            icon = { icon(display.icon.orElse(literal(Icon.Iconify("fa6-solid:cube")))) },
            details = {
                clippedRow(spacing = 0.0) {
                    searchDescription(display.name.orIfBlank("Element"))
                    showIf(page.exists) {
                        pageLocation(
                            page = page,
                            active = origin,
                            includePage = (page.id neq origin).orElse(literal(true)),
                            part = { searchDescription(it) },
                            separator = { searchDescription(literal("•")) },
                            prefixFirst = literal(true),
                        )
                    }
                }
            },
        )
    }
}

object ElementGraphNodePresentation : ElementPresentation {
    override val roles = setOf(PresentationRole.EDITOR_NODE)

    override fun ElementPresentationScope.present() {
        val element = subject.resource<Element>()
        val display = element.type.display
        entryNode(
            title = element.fields.name.orIfBlank("Unnamed element"),
            icon = display.icon.orElse(literal(Icon.Iconify("fa6-solid:cube"))),
            accent = display.color.orElse(literal(Color(0xff9c64bdu))),
        )
    }
}
