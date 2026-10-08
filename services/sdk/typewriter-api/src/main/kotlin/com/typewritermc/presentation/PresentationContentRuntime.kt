package com.typewritermc.presentation

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.literal
import com.typewritermc.types.DataValue
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.presentation.PresentationElement

internal fun PresentationLayoutHandler.text(args: Array<out Any?>) {
    val style = args.getOrNull(1) as? TextStyle ?: TextStyle()
    target +=
        state.node(
            PresentationElement.createText(
                value = expression(args[0]),
                color = style.tone?.let(::expression),
                fontSize = null,
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
                paragraph =
                    skirout.editor.v1.presentation.TextParagraph
                        .partial(),
            ),
        )
}

internal fun PresentationLayoutHandler.markdown(args: Array<out Any?>) {
    target +=
        state.node(
            PresentationElement.createMarkdown(
                value = expression(args[0]),
                color = args.getOrNull(1)?.let(::expression),
                fontSize = null,
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

internal fun PresentationLayoutHandler.icon(args: Array<out Any?>) {
    val options = args.getOrNull(1) as? IconOptions ?: IconOptions()
    target +=
        state.node(
            PresentationElement.createIcon(
                name = expression(args[0]),
                semanticLabel = null,
                color = options.color?.let(::expression),
                size = options.size?.let(::expression),
            ),
        )
}

internal fun PresentationLayoutHandler.dateTime(args: Array<out Any?>) {
    target +=
        state.node(
            PresentationElement.createDateTime(
                value = expression(args[0]),
                format = expression(args[1]),
                timeZone =
                    when (args[2] as DateTimeZone) {
                        DateTimeZone.Local -> skirout.editor.v1.presentation.DateTimeZone.LOCAL
                        DateTimeZone.Utc -> skirout.editor.v1.presentation.DateTimeZone.UTC
                    },
            ),
        )
}

internal fun PresentationLayoutHandler.richText(configuration: Any?) {
    val runs = mutableListOf<skirout.editor.v1.presentation.TextRun>()
    var overallStyle: TextStyleOverride? = null
    var overallParagraph = TextParagraph()
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

            override fun paragraph(paragraph: TextParagraph) {
                overallParagraph = paragraph
            }
        }
    invokeBlock(configuration, scope)
    target +=
        state.node(
            PresentationElement.createRichText(
                runs = runs,
                style = overallStyle?.wire(),
                paragraph = overallParagraph.wire(),
            ),
        )
}

internal fun PresentationLayoutHandler.status(args: Array<out Any?>) {
    val cases =
        (args[1] as List<*>).map { candidate ->
            candidate as StatusCase<*>
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
                value = expression(args[0]),
                cases = cases,
                fallback = (args.getOrNull(2) as? StatusAppearance)?.wire(),
            ),
        )
}

internal fun PresentationLayoutHandler.menu(args: Array<out Any?>) {
    val items = mutableListOf<skirout.editor.v1.presentation.MenuItem>()
    val scope =
        object : MenuScope {
            override fun item(
                id: String,
                label: Expr<String, Handled>,
                action: skirout.editor.v1.action.EditorAction,
            ) {
                items +=
                    skirout.editor.v1.presentation.MenuItem(
                        itemId = id,
                        label = expression(label),
                        action = action,
                    )
            }
        }
    invokeBlock(args[1], scope)
    target +=
        state.node(
            PresentationElement.createMenu(
                label = args[0]?.let(::expression),
                items = items,
            ),
        )
}

internal fun PresentationLayoutHandler.relativeTime(args: Array<out Any?>) {
    target +=
        state.node(
            PresentationElement.createRelativeTime(
                value = expression(args[0]),
                style =
                    when (args[1] as RelativeTimeStyle) {
                        RelativeTimeStyle.Compact -> skirout.editor.v1.presentation.RelativeTimeStyle.COMPACT
                        RelativeTimeStyle.Full -> skirout.editor.v1.presentation.RelativeTimeStyle.NATURAL
                    },
                timeZone =
                    when (args[2] as DateTimeZone) {
                        DateTimeZone.Local -> skirout.editor.v1.presentation.DateTimeZone.LOCAL
                        DateTimeZone.Utc -> skirout.editor.v1.presentation.DateTimeZone.UTC
                    },
            ),
        )
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
        color = tone?.let(::expression),
        fontWeight = weight?.let(::expression),
        fontItalic = null,
        decoration = null,
    )

private fun TextParagraph.wire(): skirout.editor.v1.presentation.TextParagraph =
    skirout.editor.v1.presentation.TextParagraph
        .partial(maxLines = maximumLines)

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
