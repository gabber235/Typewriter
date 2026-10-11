package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.DataValue
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import kotlin.time.Instant

internal class RuntimePresentationContent(
    private val state: PresentationBuildState,
    private val target: MutableList<PresentationNode>,
) : PresentationContent {
    override fun image(
        source: Expr<String, Handled>,
        semanticLabel: Expr<String, Handled>?,
    ) {
        target += state.node(PresentationElement.createImage(source = expression(source), semanticLabel = semanticLabel?.let(::expression)))
    }

    override fun badge(
        label: Expr<String, Handled>,
        tone: String,
    ) {
        target += state.node(PresentationElement.createBadge(label = expression(label), tone = tone))
    }

    override fun chip(
        label: Expr<String, Handled>,
        color: PresentationColor?,
    ) {
        target += state.node(PresentationElement.createChip(label = expression(label), color = color?.wire()))
    }

    override fun <N> progress(
        value: Expr<N, Handled>,
        maximum: Expr<N, Handled>,
        label: Expr<String, Handled>?,
    ) {
        target +=
            state.node(
                PresentationElement.createProgress(
                    value = expression(value),
                    maximum = expression(maximum),
                    label = label?.let(::expression),
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
                    value = expression(value),
                    color = style.color?.wire(),
                    sizing = style.sizing?.wire(),
                    fontWeight = style.weight?.let(::expression),
                    fontItalic = null,
                    fontOpticalSize = null,
                    fontSlant = null,
                    fontWidth = null,
                    textAlignment = null,
                    lineHeight = null,
                    letterSpacing = null,
                    decoration = null,
                    semanticLabel = null,
                    paragraph = paragraph.wire(),
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
                    value = expression(value),
                    color = color?.wire(),
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
    ) {
        target +=
            state.node(
                PresentationElement.createIcon(
                    name = expression(value),
                    semanticLabel = null,
                    color = options.color?.wire(),
                    size = options.size?.let(::expression),
                ),
            )
    }

    override fun dateTime(
        value: Expr<Instant, Handled>,
        format: Expr<String, Handled>,
        zone: DateTimeZone,
    ) {
        target +=
            state.node(
                PresentationElement.createDateTime(
                    value = expression(value),
                    format = expression(format),
                    timeZone =
                        when (zone) {
                            DateTimeZone.Local -> skirout.editor.v1.presentation.DateTimeZone.LOCAL
                            DateTimeZone.Utc -> skirout.editor.v1.presentation.DateTimeZone.UTC
                        },
                ),
            )
    }

    override fun richText(configure: RichTextScope.() -> Unit) {
        val runs = mutableListOf<skirout.editor.v1.presentation.TextRun>()
        var overallStyle: TextStyleOverride? = null
        var overallParagraph = TextParagraph()
        var overallSizing: TextSizing? = null
        val scope =
            object : RichTextScope {
                override fun run(
                    text: Expr<String, Handled>,
                    style: TextStyleOverride?,
                ) {
                    runs +=
                        skirout.editor.v1.presentation.TextRun(
                            text = expression(text),
                            style = style?.wire(),
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
                    style = overallStyle?.wire(),
                    paragraph = overallParagraph.wire(),
                    sizing = overallSizing?.wire(),
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
                        com.typewritermc.types.skir.SkirDataValueCodec
                            .encode(portableLiteral(candidate.value))
                            .getOrThrow(),
                    appearance = candidate.appearance.wire(),
                )
            }
        target +=
            state.node(
                PresentationElement.createStatus(
                    value = expression(value),
                    cases = wireCases,
                    fallback = fallback?.wire(),
                ),
            )
    }

    override fun relativeTime(
        value: Expr<Instant, Handled>,
        style: RelativeTimeStyle,
        zone: DateTimeZone,
    ) {
        target +=
            state.node(
                PresentationElement.createRelativeTime(
                    value = expression(value),
                    style =
                        when (style) {
                            RelativeTimeStyle.Compact -> skirout.editor.v1.presentation.RelativeTimeStyle.COMPACT
                            RelativeTimeStyle.Full -> skirout.editor.v1.presentation.RelativeTimeStyle.NATURAL
                        },
                    timeZone =
                        when (zone) {
                            DateTimeZone.Local -> skirout.editor.v1.presentation.DateTimeZone.LOCAL
                            DateTimeZone.Utc -> skirout.editor.v1.presentation.DateTimeZone.UTC
                        },
                ),
            )
    }
}

private fun portableLiteral(value: Any?): DataValue =
    when (value) {
        null -> DataValue.Null
        is DataValue -> value
        is String -> DataValue.StringValue(value)
        is Boolean -> DataValue.Boolean(value)
        is Byte -> DataValue.Integer(value.toLong().toBigInteger())
        is Short -> DataValue.Integer(value.toLong().toBigInteger())
        is Int -> DataValue.Integer(value.toBigInteger())
        is Long -> DataValue.Integer(value.toBigInteger())
        is UByte -> DataValue.Integer(value.toLong().toBigInteger())
        is UShort -> DataValue.Integer(value.toLong().toBigInteger())
        is UInt -> DataValue.Integer(value.toLong().toBigInteger())
        is ULong -> DataValue.Integer(value.toString().toBigInteger())
        is Float -> DataValue.Float(value.toDouble())
        is Double -> DataValue.Float(value)
        else -> throw IllegalArgumentException("A status case value must have a portable literal representation.")
    }

private fun TextStyleOverride.wire(): skirout.editor.v1.presentation.TextStyleOverride =
    skirout.editor.v1.presentation.TextStyleOverride(
        color = color?.wire(),
        fontWeight = weight?.let(::expression),
        fontItalic = null,
        decoration = null,
    )

private fun TextParagraph.wire(): skirout.editor.v1.presentation.TextParagraph =
    skirout.editor.v1.presentation.TextParagraph(
        maxLines = maximumLines,
        overflow =
            when (overflow) {
                TextOverflow.Clip -> skirout.editor.v1.presentation.PresentationTextOverflow.CLIP
                TextOverflow.Ellipsis -> skirout.editor.v1.presentation.PresentationTextOverflow.ELLIPSIS
            },
        softWrap = softWrap,
        selectable = selectable,
        tone =
            when (tone) {
                TextTone.Primary -> skirout.editor.v1.presentation.PresentationTextTone.PRIMARY
                TextTone.Secondary -> skirout.editor.v1.presentation.PresentationTextTone.SECONDARY
            },
    )

private fun TextSizing.wire(): skirout.editor.v1.presentation.TextSizing =
    when (this) {
        is TextSizing.Exact -> {
            skirout.editor.v1.presentation.TextSizing
                .ExactWrapper(expression(value))
        }

        is TextSizing.Fit -> {
            skirout.editor.v1.presentation.TextSizing.createFit(
                minimum = expression(minimum),
                maximum = expression(maximum),
            )
        }
    }

private fun StatusAppearance.wire(): skirout.editor.v1.presentation.StatusAppearance =
    skirout.editor.v1.presentation.StatusAppearance(
        tone = tone.wireStatusTone(),
        label = expression(label),
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
