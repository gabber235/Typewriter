package com.typewritermc.library

import com.typewritermc.configuration.generatedExpressionScope
import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.target
import com.typewritermc.presentation.AppliedPresentation
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationInput
import com.typewritermc.types.Color
import com.typewritermc.types.CoreIconSdkProvider
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconIconifyExpressions
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.IconSvgExpressions
import com.typewritermc.types.PresentationRole

object BookSdkProvider : BookConfiguration, BookPresentation {
    override val roles =
        setOf(
            PresentationRole.INSPECTOR,
            PresentationRole.REFERENCE_SUMMARY,
            PresentationRole.REFERENCE_OPTION,
            PresentationRole.INSPECTOR_HEADER,
            PresentationRole.AUTHORING_RESULT,
        )

    override fun BookConfigurationScope.configure() {
        title {
            nonBlank()
            singleLine()
        }
        color { opaque() }
    }

    override fun BookPresentationScope.present() {
        if (role == PresentationRole.INSPECTOR) {
            val tagOptions = libraryTagCollectionSource()
            inspectorLayout {
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
        } else {
            val iconInput = icon.input
            librarySubjectLayout(
                label = expressions.title.orIfBlank("Unnamed Book"),
                color = expressions.color.orElse(literal(Color(0xff3f51b5u))),
            ) {
                bookSubjectIcon(iconInput)
            }
        }
    }
}

private fun Layout.bookSubjectIcon(input: PresentationInput<Icon, *>) {
    polymorphicMatch(input) {
        case(AppliedPresentation(IconIconifyDefinition.use, CoreIconSdkProvider)) {
            val iconify = generatedExpressionScope(IconIconifyExpressions::class, value)
            icon(iconify.value.orElse(literal("material-symbols:book")))
        }
        case(AppliedPresentation(IconSvgDefinition.use, CoreIconSdkProvider)) {
            val svg = generatedExpressionScope(IconSvgExpressions::class, value)
            icon(svg.source.orElse(literal("material-symbols:book")))
        }
        fallback { icon(literal("material-symbols:book")) }
    }
}
