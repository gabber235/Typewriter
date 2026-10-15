package com.typewritermc.library

import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.target
import com.typewritermc.expression.trim
import com.typewritermc.presentation.ContainerStyle
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationAlignment
import com.typewritermc.presentation.PresentationBorder
import com.typewritermc.presentation.PresentationInteractionState.Focused
import com.typewritermc.presentation.PresentationInteractionState.Hovered
import com.typewritermc.presentation.PresentationInteractionState.Selected
import com.typewritermc.presentation.PresentationRadius
import com.typewritermc.presentation.PresentationThemeColor.FocusOutline
import com.typewritermc.presentation.ambientBackground
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.literalColor
import com.typewritermc.presentation.monochromeOn
import com.typewritermc.presentation.on
import com.typewritermc.presentation.resourceHeading
import com.typewritermc.presentation.stateColor
import com.typewritermc.presentation.themeColor
import com.typewritermc.presentation.withAlpha
import com.typewritermc.types.Color
import com.typewritermc.types.PresentationRole

object TagInspectorPresentation : TagPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun TagPresentationScope.present() {
        val tagOptions = libraryTagCollectionSource()
        inspectorLayout {
            resourceHeading(
                title = expressions.name.orIfBlank("Unnamed tag"),
                color = expressions.color.orElse(literal(Color(0xff9e9e9eu))),
                identifier = subject.identifier,
            )
            inspectorSection("name", "Name", input = name.input) {
                name { textInput { onComplete { value.trim() } } }
            }
            inspectorSection("color", "Color", input = color.input) {
                color { colorInput { includeAlpha(false) } }
            }
            inspectorSection("parents", "Direct Parents", input = parents.input) {
                parents { collectionInput { items { linkInput() } } }
            }
            tagInheritanceSection("inheritance", "Inheritance", tagOptions, expressions.parents.map { target })
            inspectorSection("placement", "Placement", input = placement.input) {
                placement(using = PlacementSdkProvider)
            }
            remainingFields {}
        }
    }
}

object TagGraphNodePresentation : TagPresentation {
    override val roles = setOf(PresentationRole.GRAPH_NODE)

    override fun TagPresentationScope.present() {
        tagGraphSurface {
            librarySubjectLayout(expressions.name.orIfBlank("Unnamed tag")) {
                icon(literal("material-symbols:label"))
            }
        }
    }
}

object TagReferencePresentation : TagPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_SUMMARY, PresentationRole.REFERENCE_OPTION, PresentationRole.AUTHORING_RESULT)

    override fun TagPresentationScope.present() {
        librarySubjectLayout(expressions.name.orIfBlank("Unnamed tag")) {
            icon(literal("material-symbols:label"))
        }
    }
}

private fun TagPresentationScope.tagGraphSurface(body: Layout.() -> Unit) {
    val accent =
        expressions.color
            .orElse(literal(Color(0xff9e9e9eu)))
            .asPresentationColor()
    val background =
        stateColor(accent.withAlpha(0.2)) {
            whenAll(Selected, Hovered, color = accent.withAlpha(0.7))
            whenAll(Selected, color = accent)
            whenAll(Hovered, color = accent.withAlpha(0.5))
        }
    val foreground =
        stateColor(accent) {
            whenAll(Hovered, color = ambientBackground().monochromeOn())
            whenAll(Selected, color = ambientBackground().on())
        }
    val outline =
        stateColor(accent) {
            whenAll(Focused, color = themeColor(FocusOutline))
            whenAll(Selected, color = literalColor(Color(0u)))
        }
    container(
        ContainerStyle(
            background = background,
            foreground = foreground,
            border = PresentationBorder.All(width = 2.0, color = outline),
            radius = PresentationRadius.Large,
            transitionMilliseconds = 100,
        ),
    ) {
        align(PresentationAlignment.Center, body)
    }
}

object PageInspectorPresentation : PagePresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun PagePresentationScope.present() {
        inspectorLayout {
            resourceHeading(
                title = expressions.name.orIfBlank("Unnamed page"),
                color = literal(Color(0xff607d8bu)),
                identifier = subject.identifier,
            )
            inspectorSection("book", "Book", input = book.input) {
                book { linkInput() }
            }
            inspectorSection("name", "Name", input = name.input) {
                name { textInput { onComplete { value.trim() } } }
            }
            inspectorSection("chapter", "Chapter", input = chapter.input) {
                chapter { textInput { onComplete { value.trim() } } }
            }
            inspectorSection("priority", "Priority", input = priority.input) {
                priority { numericInput() }
            }
            remainingFields {
                exclude(elements)
            }
        }
    }
}

object PageReferencePresentation : PagePresentation {
    override val roles =
        setOf(
            PresentationRole.REFERENCE_SUMMARY,
            PresentationRole.REFERENCE_OPTION,
            PresentationRole.PAGE_TILE,
            PresentationRole.CATALOG_OPTION,
            PresentationRole.AUTHORING_RESULT,
        )

    override fun PagePresentationScope.present() {
        librarySubjectLayout(expressions.name.orIfBlank("Unnamed page")) {
            icon(literal("material-symbols:description"))
        }
    }
}
