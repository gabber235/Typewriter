package com.typewritermc.types

import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.PresentationSpec
import com.typewritermc.presentation.TypewriterPresentation
import com.typewritermc.presentation.cache
import com.typewritermc.presentation.capture
import com.typewritermc.presentation.debounce
import com.typewritermc.presentation.distinct
import com.typewritermc.presentation.gate
import com.typewritermc.presentation.history
import com.typewritermc.presentation.limit
import com.typewritermc.presentation.matches
import com.typewritermc.presentation.orElse
import com.typewritermc.presentation.rank
import com.typewritermc.presentation.replace
import com.typewritermc.presentation.rolePresentation
import com.typewritermc.presentation.section
import com.typewritermc.presentation.titleCase
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.PresentationRole

@TypewriterPresentation(roles = [PresentationRole.EDITOR])
context(context: PresentationBuildContext)
fun coreColorEditor(): PresentationSpec<Color> = colorEditor(context)

@TypewriterPresentation(roles = [PresentationRole.EDITOR])
context(context: PresentationBuildContext)
fun coreIconifyEditor(): PresentationSpec<Icon.Iconify> = iconifyEditor(context)

@TypewriterPresentation(roles = [PresentationRole.EDITOR])
context(context: PresentationBuildContext)
fun coreSvgEditor(): PresentationSpec<Icon.Svg> = svgEditor(context)

private fun colorEditor(context: PresentationBuildContext): PresentationSpec<Color> =
    context(context) {
        rolePresentation<Color>("color.editor") {
            colorInput(editableInput<Color>("value").value())
        }
    }

private fun iconifyEditor(context: PresentationBuildContext): PresentationSpec<Icon.Iconify> =
    context(context) {
        rolePresentation<Icon.Iconify>("icon.iconify.editor") {
            val value = editableInput<Icon.Iconify>("value")
            searchInput(value.value(), String::class, placeholder = "Search icons", maximumExtent = 280) {
                val identifier = candidate.capture("^([a-z0-9-]+:[a-z0-9-]+)$", 1)
                val name = identifier.capture("^[^:]+:(.+)$", 1).replace("-", " ").titleCase()
                val collection = identifier.capture("^([^:]+):.+$", 1).replace("-", " ").titleCase()
                val selected = record(Icon.Iconify::class, field(Icon.Iconify::class, Icon.Iconify::value, identifier))

                result(key = identifier, selectedValue = selected, label = name) {
                    row(spacing = 10.0) {
                        fixed { icon(selected) }
                        flexible {
                            column(spacing = 1.0) {
                                text(name)
                                text(collection)
                            }
                        }
                    }
                }
                val current = summaryValue.field(Icon.Iconify::value)
                initialQuery(value.field(Icon.Iconify::value).expression())
                val selectedPreview = summaryValue
                summary {
                    row(spacing = 10.0) {
                        fixed { icon(selectedPreview) }
                        flexible { text(current) }
                    }
                }
                customValue(
                    record(
                        Icon.Iconify::class,
                        field(Icon.Iconify::class, Icon.Iconify::value, query.capture("^([a-z0-9-]+:[a-z0-9-]+)$", 1)),
                    ),
                )

                val term = query.capture("^(?:[^:]+:)?(.+)$", 1).orElse(query)
                val prefix = query.capture("^([^:]+):(.+)$", 1).orElse(literal(""))
                val remote =
                    httpJson(
                        uri = "https://api.iconify.design/search",
                        resultPath = "$.icons[*]",
                        timeoutMillis = 5_000,
                        parameters =
                            listOf(
                                parameter("query", term),
                                parameter("prefix", prefix, omitIfEmpty = true),
                                parameter("limit", literal("64")),
                            ),
                    ).gate(term.matches("^.{2,}$"), guidance = "Enter at least two characters")
                        .debounce(150)
                        .rank(name to 100, collection to 40, identifier to 30)
                        .limit(64)
                        .cache(capacity = 100, retainStaleResults = true)
                        .history(key = "iconify", label = "Recent", capacity = 10)
                        .section(id = "iconify.remote", label = "Iconify")
                val suggested =
                    staticValues(
                        listOf("mdi:home", "mdi:account", "mdi:star", "mdi:map-marker", "game-icons:broad-dagger"),
                    ).rank(name to 100)
                        .section(id = "iconify.suggested", label = "Suggested")
                provider(merge(remote, suggested).distinct())
            }
        }
    }

private fun svgEditor(context: PresentationBuildContext): PresentationSpec<Icon.Svg> =
    context(context) {
        rolePresentation<Icon.Svg>("icon.svg.editor") {
            val value = editableInput<Icon.Svg>("value")
            textInput(value.field(Icon.Svg::source), multiline = true)
        }
    }
