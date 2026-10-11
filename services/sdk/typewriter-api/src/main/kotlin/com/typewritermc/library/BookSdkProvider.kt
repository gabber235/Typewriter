package com.typewritermc.library

import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.target
import com.typewritermc.presentation.AppliedPresentation
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationInput
import com.typewritermc.presentation.resourceHeading
import com.typewritermc.types.Color
import com.typewritermc.types.CoreIconSdkProvider
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconIconifyExpressionsFactory
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.IconSvgExpressionsFactory
import com.typewritermc.types.PresentationRole

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
                identifier = subject.identifier,
            )
            inspectorSection("title", "Title") {
                title { textInput() }
            }
            inspectorSection("icon", "Icon") {
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
            inspectorSection("color", "Color") {
                color { colorInput(includeAlpha = false) }
            }
            inspectorSection("tags", "Direct Tags") {
                tags { collectionInput { linkInput(source = tagOptions) } }
            }
            inspectorSection("effective-tags", "Effective Tags") {
                collectionGraph(tagOptions) {
                    roots(
                        expressions.tags
                            .map { target }
                            .orElse(emptyListExpression()),
                    )
                    relation("parents")
                    node { tagGraphNode() }
                }
            }
            remainingFields {
                exclude(title)
                exclude(icon)
                exclude(color)
                exclude(tags)
                exclude(pages)
            }
        }
    }
}

object BookReferencePresentation : BookPresentation {
    override val roles = setOf(PresentationRole.REFERENCE_SUMMARY, PresentationRole.REFERENCE_OPTION, PresentationRole.AUTHORING_RESULT)

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
