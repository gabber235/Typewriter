package com.typewritermc.types

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.length
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.expression.shortcuts.gte
import com.typewritermc.presentation.Spacing
import com.typewritermc.presentation.TextLines
import com.typewritermc.presentation.cache
import com.typewritermc.presentation.debounce
import com.typewritermc.presentation.distinct
import com.typewritermc.presentation.gate
import com.typewritermc.presentation.history
import com.typewritermc.presentation.limit
import com.typewritermc.presentation.section
import com.typewritermc.presentation.textParagraph
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.presentation.PresentationTextOverflow
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ScalarKind
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

object CoreIconSdkProvider : IconIconifyPresentation, IconSvgPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)
    override val priority = 0

    override fun IconIconifyPresentationScope.present() {
        val current = expressions.value.orElse(literal(""))
        value {
            semanticLabel(literal("Icon"))
            searchInput<String> {
                placeholder(literal("Search icons"))
                maximumExtent(literal(280.0))
                initialQuery(current)
                customValue(query)
                result {
                    key(row)
                    selectedValue(row)
                    label(row)
                    presentation {
                        row(spacing = Spacing(10.0)) {
                            icon(row)
                            flexible {
                                text(row, paragraph = textParagraph(maxLines = 1, overflow = PresentationTextOverflow.ELLIPSIS))
                            }
                        }
                    }
                }
                summary {
                    row(spacing = Spacing(10.0)) {
                        icon(current.orElse(literal("material-symbols:book")))
                        flexible {
                            text(current, paragraph = textParagraph(maxLines = 1, overflow = PresentationTextOverflow.ELLIPSIS))
                        }
                    }
                }
                val remote =
                    sources
                        .httpJson<String> {
                            uri(literal("https://api.iconify.design/search"))
                            parameter("query", query)
                            parameter("limit", literal("64"))
                            result("$.icons[*]", ScalarKind.TEXT.template)
                            timeout(5.seconds)
                        }.gate(query.length gte 2, literal("Enter at least two characters"))
                        .debounce(150.milliseconds)
                        .limit(literal(64))
                        .cache(capacity = 100, retainStaleResults = true)
                        .history(key = "iconify", label = literal("Recent"), capacity = 10)
                        .section(id = "iconify.remote", label = literal("Iconify"))
                val suggestions =
                    sources
                        .staticValues(suggestedIcons)
                        .section(id = "iconify.suggested", label = literal("Suggested"))
                provider(sources.merge(remote, suggestions).distinct())
            }
        }
        remainingFields()
    }

    override fun IconSvgPresentationScope.present() {
        source {
            label("SVG source")
            textInput { lines(TextLines.Multiple()) }
        }
        remainingFields()
    }
}

private val suggestedIcons: Expr<List<String>, Handled> =
    com.typewritermc.expression.portableLiteral(
        DataValue.listValue(
            listOf("mdi:home", "mdi:account", "mdi:star", "mdi:map-marker", "game-icons:broad-dagger")
                .mapIndexed {
                    index,
                    icon,
                    ->
                    ListItem(id = ItemId(value = "icon.suggestion.$index"), value = DataValue.StringValueWrapper(icon))
                },
        ),
    )
