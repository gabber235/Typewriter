package com.typewritermc.library

import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.expression.accent
import com.typewritermc.expression.color
import com.typewritermc.expression.display
import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.icon
import com.typewritermc.expression.label
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.name
import com.typewritermc.expression.orElse
import com.typewritermc.expression.orIfBlank
import com.typewritermc.expression.target
import com.typewritermc.expression.trim
import com.typewritermc.presentation.ContainerStyle
import com.typewritermc.presentation.EditorContext
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationBorder
import com.typewritermc.presentation.PresentationRadius
import com.typewritermc.presentation.ambientBackground
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.icon
import com.typewritermc.presentation.literalColor
import com.typewritermc.presentation.monochromeOn
import com.typewritermc.presentation.on
import com.typewritermc.presentation.resource
import com.typewritermc.presentation.resourceHeading
import com.typewritermc.presentation.searchChip
import com.typewritermc.presentation.searchDescription
import com.typewritermc.presentation.stateColor
import com.typewritermc.presentation.stateTransition
import com.typewritermc.presentation.themeColor
import com.typewritermc.presentation.transition
import com.typewritermc.presentation.withAlpha
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Ref
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationInteractionState.FOCUSED
import skirout.editor.v1.presentation.PresentationInteractionState.HOVERED
import skirout.editor.v1.presentation.PresentationInteractionState.SELECTED
import skirout.editor.v1.presentation.PresentationThemeColor.FOCUS_OUTLINE

object TagInspectorPresentation : TagPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun TagPresentationScope.present() {
        val tagOptions = libraryTagCollectionSource()
        inspectorLayout {
            resourceHeading(title = appearance.label, color = appearance.accent)
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
            remainingFields {
                exclude(taxonomy)
            }
        }
    }
}

/** The tags section: every tag placed on a graph, with edges from the parents links among them. */
object TaxonomyWorkspace : TaxonomyPresentation {
    override val roles = setOf(PresentationRole.WORKSPACE)

    override fun TaxonomyPresentationScope.present() {
        tags { graph(GraphDirection.TOP_TO_BOTTOM) }
    }
}

object TagGraphNodePresentation : TagPresentation {
    override val roles = setOf(PresentationRole.ITEM)

    override fun TagPresentationScope.present() {
        tagGraphSurface {
            librarySubjectLayout(appearance.label) { icon(appearance.icon) }
        }
    }
}

object TagReferencePresentation : TagPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_PREVIEW)

    override fun TagPresentationScope.present() {
        librarySubjectLayout(appearance.label) { icon(appearance.icon) }
    }
}

private fun TagPresentationScope.tagGraphSurface(body: Layout.() -> Unit) {
    val accent = appearance.accent.asPresentationColor()
    val background =
        stateColor(accent.withAlpha(0.2)) {
            whenAll(SELECTED, HOVERED, color = accent.withAlpha(0.7))
            whenAll(SELECTED, color = accent)
            whenAll(HOVERED, color = accent.withAlpha(0.5))
        }
    val foreground =
        stateColor(accent) {
            whenAll(HOVERED, color = ambientBackground().monochromeOn())
            whenAll(SELECTED, color = ambientBackground().on())
        }
    val outline =
        stateColor(accent) {
            whenAll(FOCUSED, color = themeColor(FOCUS_OUTLINE))
            whenAll(SELECTED, color = literalColor(Color(0u)))
        }
    container(
        ContainerStyle(
            background = background,
            foreground = foreground,
            border = PresentationBorder.All(width = 2.0, color = outline),
            radius = PresentationRadius.Large,
            transition = stateTransition(transition(milliseconds = 100)),
        ),
    ) {
        align(PresentationAlignment.CENTER, body)
    }
}

object PageInspectorPresentation : PagePresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun PagePresentationScope.present() {
        inspectorLayout {
            resourceHeading(title = appearance.label, color = appearance.accent)
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
    override val roles = setOf(PresentationRole.REFERENCE_PREVIEW)

    override fun PagePresentationScope.present() {
        librarySubjectLayout(appearance.label) { icon(appearance.icon) }
    }
}

/**
 * Parent tag chips under the Tag's name in search rows and pickers; the host draws the name, accent and icon. Each chip
 * shows another resource, a parent Tag, so it reads that Tag's own fields rather than the subject's appearance.
 */
object TagSearchPresentation : TagPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_PICKER_RESULT, PresentationRole.RESOURCE_SEARCH_RESULT)

    override fun TagPresentationScope.present() {
        repeated<Ref<TagParents.Child, Tag>, Ref<TagParents.Child, Tag>>(expressions.parents.map { this }.orElse(emptyListExpression())) {
            clippedRow(spacing = 4.0)
            val parent = item.resource
            showIf(parent.exists) {
                searchChip(
                    parent.fields.name.orIfBlank("Unnamed tag"),
                    parent.fields.color
                        .orElse(literal(Color(0xff9e9e9eu)))
                        .asPresentationColor(),
                )
            }
        }
    }
}

/** Where a Page sits, under its name in search rows and pickers; the host draws the name, accent and icon. */
object PageSearchPresentation : PagePresentation {
    override val roles = setOf(PresentationRole.REFERENCE_PICKER_RESULT, PresentationRole.RESOURCE_SEARCH_RESULT)

    override fun PagePresentationScope.present() {
        val page = subject.resource<Page>()
        val origin = context.read(EditorContext.activeResource)
        val accent = appearance.accent.asPresentationColor()
        pageLocation(
            page = page,
            active = origin,
            includePage = literal(false),
            part = { searchChip(it, accent) },
            separator = { icon(literal("material-symbols:chevron-right-rounded")) },
        )
    }
}
