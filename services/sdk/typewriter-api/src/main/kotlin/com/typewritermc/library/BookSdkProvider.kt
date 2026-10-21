package com.typewritermc.library

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.accent
import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.gt
import com.typewritermc.expression.icon
import com.typewritermc.expression.label
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.orIfBlank
import com.typewritermc.expression.size
import com.typewritermc.expression.take
import com.typewritermc.expression.target
import com.typewritermc.expression.trim
import com.typewritermc.presentation.AppliedPresentation
import com.typewritermc.presentation.ContainerStyle
import com.typewritermc.presentation.IconOptions
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationColor
import com.typewritermc.presentation.PresentationInput
import com.typewritermc.presentation.PresentationInsets
import com.typewritermc.presentation.PresentationRadius
import com.typewritermc.presentation.TextSizing
import com.typewritermc.presentation.TextStyle
import com.typewritermc.presentation.adjusted
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.brightnessColor
import com.typewritermc.presentation.createResource
import com.typewritermc.presentation.focusRing
import com.typewritermc.presentation.hoverLift
import com.typewritermc.presentation.icon
import com.typewritermc.presentation.resource
import com.typewritermc.presentation.resourceHeading
import com.typewritermc.presentation.searchChip
import com.typewritermc.presentation.stackedCard
import com.typewritermc.types.Color
import com.typewritermc.types.CoreIconSdkProvider
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconIconifyExpressionsFactory
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.IconSvgExpressionsFactory
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Ref
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PresentationAlignment

object BookConfigurationProvider : BookConfiguration {
    override fun BookConfigurationScope.configure() {
        title {
            nonBlank()
            singleLine()
        }
        color { opaque() }
    }
}

object BookInspectorPresentation : BookPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun BookPresentationScope.present() {
        val tagOptions = libraryTagCollectionSource()
        inspectorLayout {
            resourceHeading(title = appearance.label, color = appearance.accent)
            inspectorSection("title", "Title", input = title.input) {
                title { textInput { onComplete { value.trim() } } }
            }
            inspectorSection("icon", "Icon", input = icon.input) {
                icon {
                    polymorphicInput {
                        form(
                            AppliedPresentation(IconIconifyDefinition.use, CoreIconSdkProvider),
                            literal("Iconify"),
                        )
                        form(
                            AppliedPresentation(IconSvgDefinition.use, CoreIconSdkProvider),
                            literal("SVG"),
                        )
                    }
                }
            }
            inspectorSection("color", "Color", input = color.input) {
                color { colorInput { includeAlpha(false) } }
            }
            inspectorSection("tags", "Direct Tags", input = tags.input) {
                tags { collectionInput { items { linkInput(source = tagOptions) } } }
            }
            tagInheritanceSection("effective-tags", "Effective Tags", tagOptions, expressions.tags.map { target })
            remainingFields {
                exclude(library)
                exclude(pages)
            }
        }
    }
}

/** The Library: every Book as a card. */
object LibraryWorkspace : LibraryPresentation {
    override val roles = setOf(PresentationRole.WORKSPACE)

    override fun LibraryPresentationScope.present() {
        books {
            grid(itemExtent = 240.0, aspectRatio = 0.72, spacing = 16.0)
        }
    }
}

/** The chapter tree of a Book beside the Book and each of its pages. */
object BookOutline : BookPresentation {
    override val roles = setOf(PresentationRole.NAVIGATOR)

    override fun BookPresentationScope.present() {
        pages {
            order { resource.fields.name.orElse(literal("")) }
            tree(path = PageFields.chapter) {
                group {
                    text(group.name)
                    button(
                        label = literal("New page"),
                        action = createResource(type = PageDefinition.id, owner = BookFields.pages) { PageFields.chapter(group.path) },
                    )
                }
            }
        }
    }
}

object BookReferencePresentation : BookPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_PREVIEW)

    override fun BookPresentationScope.present() {
        librarySubjectLayout(appearance.label) { icon(appearance.icon) }
    }
}

/**
 * Tag chips under the Book's name in search rows and pickers; the host draws the name, accent and icon. Each chip shows
 * a tagged Tag, another resource, so it reads that Tag's own fields rather than the subject's appearance.
 */
object BookSearchPresentation : BookPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_PICKER_RESULT, PresentationRole.RESOURCE_SEARCH_RESULT)

    override fun BookPresentationScope.present() {
        val accent = appearance.accent.asPresentationColor()
        repeated<Ref<BookTags.Book, Tag>, Ref<BookTags.Book, Tag>>(bookTags()) {
            clippedRow(spacing = 4.0)
            val tag = item.resource
            showIf(tag.exists, whenFalse = { searchChip(literal("Unavailable tag"), accent) }) {
                searchChip(
                    tag.fields.name.orIfBlank("Unnamed tag"),
                    tag.fields.color
                        .orElse(literal(UNTAGGED))
                        .asPresentationColor(),
                )
            }
        }
    }
}

/** The Book as a standing volume in grids, graphs and trees. Search rows keep the uniform host chrome. */
object BookItemPresentation : BookPresentation {
    override val roles = setOf(PresentationRole.ITEM)

    override fun BookPresentationScope.present() {
        val accent = appearance.accent.asPresentationColor()
        val tags = bookTags()
        // The grid gives every item its whole cell; the volume keeps its size in the middle of it.
        align(PresentationAlignment.CENTER) {
            focusRing(accent) {
                hoverLift {
                    stackedCard(accent = accent, width = 175.0, height = 230.0) {
                        column(main = MainAxisAlignment.SPACE_BETWEEN, cross = CrossAxisAlignment.STRETCH) {
                            fixed { align(PresentationAlignment.CENTER_START) { icon(appearance.icon, IconOptions(size = 28.0)) } }
                            flexible {
                                text(
                                    appearance.label,
                                    style =
                                        TextStyle(
                                            sizing = TextSizing.Fit(minimum = literal(12.0), maximum = literal(16.0)),
                                            weight = 700,
                                        ),
                                )
                            }
                            fixed { bookTagBars(tags, accent = accent, limit = 4) }
                        }
                    }
                }
            }
        }
    }
}

private val UNTAGGED = Color(0xff9e9e9eu)

private fun BookPresentationScope.bookTags() = expressions.tags.map { this }.orElse(emptyListExpression())

/** The first [limit] tags of a Book as color bars on a panel tinted from [accent]; nothing without tags. */
private fun Layout.bookTagBars(
    tags: Expr<List<Ref<BookTags.Book, Tag>>, Handled>,
    accent: PresentationColor,
    limit: Int,
) {
    showIf(tags.size gt 0) {
        container(
            ContainerStyle(
                radius = PresentationRadius.Small,
                background =
                    brightnessColor(
                        light = accent.adjusted(lightness = 0.5, chroma = -0.5),
                        dark = accent.adjusted(lightness = -0.5, chroma = -0.5),
                    ),
            ),
        ) {
            padding(PresentationInsets(4.0, 4.0, 4.0, 4.0)) {
                repeated<Ref<BookTags.Book, Tag>, Ref<BookTags.Book, Tag>>(tags.take(literal(limit)).orElse(emptyListExpression())) {
                    column(spacing = 5.0, cross = CrossAxisAlignment.STRETCH)
                    val color =
                        item.resource.fields.color
                            .orElse(literal(UNTAGGED))
                    container(
                        ContainerStyle(background = color.asPresentationColor(), radius = PresentationRadius.Custom(literal(1000.0))),
                    ) {
                        size(height = 8.0) {}
                    }
                }
            }
        }
    }
}
