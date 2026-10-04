package com.typewritermc.library

import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.expression.emptyListExpression
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.orElse
import com.typewritermc.expression.target
import com.typewritermc.types.Color
import com.typewritermc.types.PresentationRole

object TagSdkProvider : TagPresentation {
    override val roles =
        setOf(
            PresentationRole.INSPECTOR,
            PresentationRole.REFERENCE_SUMMARY,
            PresentationRole.REFERENCE_OPTION,
            PresentationRole.GRAPH_NODE,
            PresentationRole.INSPECTOR_HEADER,
            PresentationRole.AUTHORING_RESULT,
        )

    override fun TagPresentationScope.present() {
        if (role == PresentationRole.INSPECTOR) {
            val tagOptions = libraryTagCollectionSource()
            inspectorLayout {
                inspectorSection("name", "Name") {
                    name { textInput() }
                }
                inspectorSection("color", "Color") {
                    color { colorInput(includeAlpha = false) }
                }
                inspectorSection("parents", "Direct Parents") {
                    parents { collectionInput { linkInput() } }
                }
                inspectorSection("inheritance", "Inheritance") {
                    collectionGraph(tagOptions) {
                        roots(
                            expressions.parents
                                .map { target }
                                .orElse(emptyListExpression()),
                        )
                        relation("parents")
                        node { tagGraphNode() }
                    }
                }
                inspectorSection("placement", "Placement") {
                    placement(using = PlacementSdkProvider)
                }
                remainingFields {
                    exclude(name)
                    exclude(color)
                    exclude(parents)
                    exclude(placement)
                }
            }
        } else {
            librarySubjectLayout(
                label = expressions.name.orIfBlank("Unnamed tag"),
                color = expressions.color.orElse(literal(Color(0xff9e9e9eu))),
            ) {
                icon(literal("material-symbols:label"))
            }
        }
    }
}

object PageSdkProvider : PagePresentation {
    override val roles =
        setOf(
            PresentationRole.INSPECTOR,
            PresentationRole.REFERENCE_SUMMARY,
            PresentationRole.REFERENCE_OPTION,
            PresentationRole.PAGE_TILE,
            PresentationRole.INSPECTOR_HEADER,
            PresentationRole.CATALOG_OPTION,
            PresentationRole.AUTHORING_RESULT,
        )

    override fun PagePresentationScope.present() {
        if (role == PresentationRole.INSPECTOR) {
            inspectorLayout {
                inspectorSection("book", "Book") {
                    book { linkInput() }
                }
                inspectorSection("name", "Name") {
                    name { textInput() }
                }
                inspectorSection("chapter", "Chapter") {
                    chapter { textInput() }
                }
                inspectorSection("priority", "Priority") {
                    priority { numericInput() }
                }
                remainingFields {
                    exclude(book)
                    exclude(name)
                    exclude(chapter)
                    exclude(priority)
                    exclude(elements)
                }
            }
        } else {
            librarySubjectLayout(expressions.name.orIfBlank("Unnamed page")) {
                icon(literal("material-symbols:description"))
            }
        }
    }
}
