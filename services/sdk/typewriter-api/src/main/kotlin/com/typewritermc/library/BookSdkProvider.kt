package com.typewritermc.library

import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.orIfBlank
import com.typewritermc.expression.target
import com.typewritermc.expression.trim
import com.typewritermc.presentation.AppliedPresentation
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationInput
import com.typewritermc.presentation.asPresentationColor
import com.typewritermc.presentation.createResource
import com.typewritermc.presentation.resource
import com.typewritermc.presentation.resourceHeading
import com.typewritermc.presentation.resourceSearchResult
import com.typewritermc.presentation.searchChip
import com.typewritermc.types.Color
import com.typewritermc.types.CoreIconSdkProvider
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconIconifyExpressionsFactory
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.IconSvgExpressionsFactory
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Ref

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
            resourceHeading(
                title = expressions.title.orIfBlank("Unnamed Book"),
                color = expressions.color.orElse(literal(Color(0xff3f51b5u))),
            )
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
        val iconInput = icon.input
        librarySubjectLayout(expressions.title.orIfBlank("Unnamed Book")) {
            bookSubjectIcon(iconInput)
        }
    }
}

private fun Layout.bookSubjectIcon(input: PresentationInput<Icon, *>) {
    polymorphicMatch(input) {
        case(AppliedPresentation(IconIconifyDefinition.use, CoreIconSdkProvider)) {
            val iconify = IconIconifyExpressionsFactory.create(value)
            icon(iconify.value.orElse(literal("material-symbols:book")))
        }
        case(AppliedPresentation(IconSvgDefinition.use, CoreIconSdkProvider)) {
            val svg = IconSvgExpressionsFactory.create(value)
            icon(svg.source.orElse(literal("material-symbols:book")))
        }
        fallback { icon(literal("material-symbols:book")) }
    }
}

object BookSearchPresentation : BookPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_PICKER_RESULT, PresentationRole.RESOURCE_SEARCH_RESULT)

    override fun BookPresentationScope.present() {
        val authoredIcon = icon.input
        val color = expressions.color.orElse(literal(Color(0xff3f51b5u)))
        resourceSearchResult(
            title = expressions.title.orIfBlank("Unnamed Book"),
            accent = color,
            kind = literal("book"),
            icon = { bookSubjectIcon(authoredIcon) },
            details = {
                repeated<Ref<BookTags.Book, Tag>, Ref<BookTags.Book, Tag>>(
                    expressions.tags.map { this }.orElse(emptyListExpression()),
                ) {
                    clippedRow(spacing = 4.0)
                    val tag = item.resource
                    showIf(tag.exists, whenFalse = {
                        searchChip(literal("Unavailable tag"), color.asPresentationColor())
                    }) {
                        searchChip(
                            tag.fields.name.orIfBlank("Unnamed tag"),
                            tag.fields.color
                                .orElse(literal(Color(0xff9e9e9eu)))
                                .asPresentationColor(),
                        )
                    }
                }
            },
        )
    }
}
