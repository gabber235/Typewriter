package com.typewritermc.types

import com.typewritermc.authoring.ItemId
import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.gte
import com.typewritermc.expression.length
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.presentation.cache
import com.typewritermc.presentation.debounce
import com.typewritermc.presentation.distinct
import com.typewritermc.presentation.gate
import com.typewritermc.presentation.history
import com.typewritermc.presentation.limit
import com.typewritermc.presentation.section
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

object CoreIconSdkProvider : IconIconifyPresentation, IconSvgPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)
    override val priority = 0

    override fun IconIconifyPresentationScope.present() {
        val current = expressions.value.orElse(literal(""))
        value {
            label("Iconify identifier")
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
                        row(spacing = 10.0) {
                            icon(row)
                            text(row)
                        }
                    }
                }
                summary {
                    row(spacing = 10.0) {
                        icon(current.orElse(literal("material-symbols:book")))
                        text(current)
                    }
                }
                val remote =
                    sources
                        .httpJson<String> {
                            uri(literal("https://api.iconify.design/search"))
                            parameter("query", query)
                            parameter("limit", literal("64"))
                            result("$.icons[*]", TypeTemplate.Scalar(ScalarKind.Text))
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
        remainingFields { exclude(value) }
    }

    override fun IconSvgPresentationScope.present() {
        source {
            label("SVG source")
            textInput(multiline = true)
        }
        remainingFields { exclude(source) }
    }
}

private val suggestedIcons: Expr<List<String>, Handled> =
    Expr(
        ExpressionNode.Literal(
            DataValue.ListValue(
                listOf("mdi:home", "mdi:account", "mdi:star", "mdi:map-marker", "game-icons:broad-dagger")
                    .mapIndexed { index, icon -> ListItem(ItemId("icon.suggestion.$index"), DataValue.StringValue(icon)) },
            ),
        ),
    )
