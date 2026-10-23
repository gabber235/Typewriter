package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.Icon
import com.typewritermc.types.IconDefinition
import com.typewritermc.types.integer
import com.typewritermc.types.requirePortable
import com.typewritermc.types.template
import skirout.editor.v1.presentation.DateTimeZone
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.RelativeTimeStyle
import skirout.editor.v1.presentation.TextParagraph
import skirout.editor.v1.type_catalog.DataValue
import kotlin.time.Instant

internal class RuntimePresentationContent(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
) : PresentationContent {
    override fun image(
        source: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>?,
        configure: ImageScope.() -> Unit,
    ) {
        val options =
            skirout.editor.v1.presentation.ImageOptions
                .partial()
                .toMutable()
        RuntimeImageScope(state, options).configure()
        target +=
            state.node(
                PresentationElement.createImage(
                    source = state.lower(source, TEXT_SLOT),
                    semanticLabel = semanticLabel?.let { state.lower(it, TEXT_SLOT) },
                    options = options.toFrozen(),
                ),
            )
    }

    override fun badge(
        label: Expr<String, Handled>,
        configure: DisplayAppearanceScope.() -> Unit,
    ) {
        target +=
            state.node(PresentationElement.createBadge(label = state.lower(label, TEXT_SLOT), options = state.displayAppearance(configure)))
    }

    override fun chip(
        label: Expr<String, Handled>,
        color: PresentationColor?,
        configure: DisplayAppearanceScope.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createChip(
                    label = state.lower(label, TEXT_SLOT),
                    color = color?.wire(state),
                    options = state.displayAppearance(configure),
                ),
            )
    }

    override fun <N> progress(
        value: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        label: Expr<String, Handled>?,
        configure: ProgressAppearanceScope.() -> Unit,
    ) {
        val appearance =
            skirout.editor.v1.presentation.ProgressAppearance
                .partial()
                .toMutable()
        RuntimeProgressAppearanceScope(state, appearance).configure()
        val (progress, number) = state.lowerInferred(value)
        target +=
            state.node(
                PresentationElement.createProgress(
                    value = progress,
                    maximum = state.lower(maximum, number),
                    label = label?.let { state.lower(it, TEXT_SLOT) },
                    appearance = appearance.toFrozen(),
                ),
            )
    }

    override fun text(
        value: Expr<String, Handled>,
        style: TextStyle,
        paragraph: TextParagraph,
    ) {
        target +=
            state.node(
                PresentationElement.createText(
                    value = state.lower(value, TEXT_SLOT),
                    color = style.color?.wire(state),
                    sizing = style.sizing?.wire(state),
                    fontWeight = style.weight?.let { state.lower(literal(it.value), INT_SLOT) },
                    fontItalic = null,
                    fontOpticalSize = null,
                    fontSlant = null,
                    fontWidth = null,
                    textAlignment = null,
                    lineHeight = style.lineHeight?.let { state.lower(literal(it), DOUBLE_SLOT) },
                    letterSpacing = null,
                    decoration = null,
                    semanticLabel = null,
                    paragraph = paragraph,
                ),
            )
    }

    override fun markdown(
        value: Expr<String, Handled>,
        color: PresentationColor?,
    ) {
        target +=
            state.node(
                PresentationElement.createMarkdown(
                    value = state.lower(value, TEXT_SLOT),
                    color = color?.wire(state),
                    sizing = null,
                    fontWeight = null,
                    fontItalic = null,
                    fontOpticalSize = null,
                    fontSlant = null,
                    fontWidth = null,
                    textAlignment = null,
                    lineHeight = null,
                    letterSpacing = null,
                    decoration = null,
                    semanticLabel = null,
                    paragraph =
                        skirout.editor.v1.presentation.TextParagraph
                            .partial(),
                ),
            )
    }

    override fun icon(
        value: Expr<String, Handled>,
        options: IconOptions,
    ) = iconElement(state.lower(value, TEXT_SLOT), options)

    override fun iconValue(
        value: Expr<Icon, Handled>,
        options: IconOptions,
    ) = iconElement(state.lower(value, IconDefinition.id.template()), options)

    /** One icon element for an Iconify name or a typed [Icon]; the wire expression carries either. */
    private fun iconElement(
        name: skirout.editor.v1.expression.ExpressionNode,
        options: IconOptions,
    ) {
        target +=
            state.node(
                PresentationElement.createIcon(
                    name = name,
                    semanticLabel = null,
                    color = options.color?.wire(state),
                    size = options.size?.let { state.lower(literal(it), DOUBLE_SLOT) },
                ),
            )
    }

    override fun dateTime(
        value: Expr<Instant, Handled>,
        format: Expr<String, Handled>,
        zone: DateTimeZone,
        configure: DisplayAppearanceScope.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createDateTime(
                    value = state.lower(value, TIMESTAMP_SLOT),
                    options = state.displayAppearance(configure),
                    format = state.lower(format, TEXT_SLOT),
                    timeZone = zone,
                ),
            )
    }

    override fun richText(configure: RichTextScope.() -> Unit) {
        val runs = mutableListOf<skirout.editor.v1.presentation.TextRun>()
        var overallStyle: TextStyleOverride? = null
        var overallParagraph = textParagraph()
        var overallSizing: TextSizing? = null
        val scope =
            object : RichTextScope {
                override fun run(
                    text: Expr<String, Handled>,
                    style: TextStyleOverride?,
                ) {
                    runs +=
                        skirout.editor.v1.presentation.TextRun(
                            text = state.lower(text, TEXT_SLOT),
                            style = style?.wire(state),
                        )
                }

                override fun style(style: TextStyleOverride) {
                    overallStyle = style
                }

                override fun sizing(sizing: TextSizing) {
                    overallSizing = sizing
                }

                override fun paragraph(paragraph: TextParagraph) {
                    overallParagraph = paragraph
                }
            }
        scope.configure()
        target +=
            state.node(
                PresentationElement.createRichText(
                    runs = runs,
                    style = overallStyle?.wire(state),
                    paragraph = overallParagraph,
                    sizing = overallSizing?.wire(state),
                ),
            )
    }

    override fun <V> status(
        value: Expr<V, Handled>,
        cases: List<StatusCase<V>>,
        fallback: StatusAppearance?,
    ) {
        val wireCases =
            cases.map { candidate ->
                skirout.editor.v1.presentation.StatusCase(
                    match =
                        portableLiteral(candidate.value).requirePortable(),
                    appearance = candidate.appearance.wire(state),
                )
            }
        target +=
            state.node(
                PresentationElement.createStatus(
                    value = state.lowerInferred(value).first,
                    cases = wireCases,
                    fallback = fallback?.wire(state),
                ),
            )
    }

    override fun relativeTime(
        value: Expr<Instant, Handled>,
        style: RelativeTimeStyle,
        zone: DateTimeZone,
        configure: DisplayAppearanceScope.() -> Unit,
    ) {
        target +=
            state.node(
                PresentationElement.createRelativeTime(
                    value = state.lower(value, TIMESTAMP_SLOT),
                    options = state.displayAppearance(configure),
                    style = style,
                    timeZone = zone,
                ),
            )
    }
}

private fun portableLiteral(value: Any?): DataValue =
    when (value) {
        null -> DataValue.NULL
        is DataValue -> value
        is String -> DataValue.StringValueWrapper(value)
        is Boolean -> DataValue.BooleanWrapper(value)
        is Byte -> DataValue.integer(value.toLong().toBigInteger())
        is Short -> DataValue.integer(value.toLong().toBigInteger())
        is Int -> DataValue.integer(value.toBigInteger())
        is Long -> DataValue.integer(value.toBigInteger())
        is UByte -> DataValue.integer(value.toLong().toBigInteger())
        is UShort -> DataValue.integer(value.toLong().toBigInteger())
        is UInt -> DataValue.integer(value.toLong().toBigInteger())
        is ULong -> DataValue.integer(value.toString().toBigInteger())
        is Float -> DataValue.FloatWrapper(value.toDouble())
        is Double -> DataValue.FloatWrapper(value)
        else -> throw IllegalArgumentException("A status case value must have a portable literal representation.")
    }

private fun TextStyleOverride.wire(state: PresentationBuildState): skirout.editor.v1.presentation.TextStyleOverride =
    skirout.editor.v1.presentation.TextStyleOverride(
        color = color?.wire(state),
        fontWeight = weight?.let { state.lower(literal(it.value), INT_SLOT) },
        fontItalic = null,
        decoration = null,
    )

internal fun TextSizing.wire(state: PresentationBuildState): skirout.editor.v1.presentation.TextSizing =
    when (this) {
        is TextSizing.Exact -> {
            skirout.editor.v1.presentation.TextSizing
                .ExactWrapper(state.lower(value, DOUBLE_SLOT))
        }

        is TextSizing.Fit -> {
            skirout.editor.v1.presentation.TextSizing.createFit(
                minimum = state.lower(minimum, DOUBLE_SLOT),
                maximum = state.lower(maximum, DOUBLE_SLOT),
            )
        }
    }

private fun StatusAppearance.wire(state: PresentationBuildState): skirout.editor.v1.presentation.StatusAppearance =
    skirout.editor.v1.presentation.StatusAppearance(
        tone = tone.wireStatusTone(),
        label = state.lower(literal(label), TEXT_SLOT),
        options = state.displayAppearance(configure),
    )

private fun String.wireStatusTone(): skirout.editor.v1.presentation.StatusTone =
    when (lowercase()) {
        "neutral" -> skirout.editor.v1.presentation.StatusTone.NEUTRAL
        "unknown" -> skirout.editor.v1.presentation.StatusTone.UNKNOWN_STATUS
        "information", "info" -> skirout.editor.v1.presentation.StatusTone.INFORMATION
        "success" -> skirout.editor.v1.presentation.StatusTone.SUCCESS
        "warning" -> skirout.editor.v1.presentation.StatusTone.WARNING
        "danger", "error" -> skirout.editor.v1.presentation.StatusTone.DANGER
        "active" -> skirout.editor.v1.presentation.StatusTone.ACTIVE
        "inactive" -> skirout.editor.v1.presentation.StatusTone.INACTIVE
        "online" -> skirout.editor.v1.presentation.StatusTone.ONLINE
        "offline" -> skirout.editor.v1.presentation.StatusTone.OFFLINE
        "pending" -> skirout.editor.v1.presentation.StatusTone.PENDING
        "in_progress" -> skirout.editor.v1.presentation.StatusTone.IN_PROGRESS
        "paused" -> skirout.editor.v1.presentation.StatusTone.PAUSED
        else -> throw IllegalArgumentException("Unknown status tone $this.")
    }
