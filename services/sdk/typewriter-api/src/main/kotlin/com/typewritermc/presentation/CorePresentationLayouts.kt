package com.typewritermc.presentation

import com.typewritermc.authoring.AuthoringSearchContext
import com.typewritermc.authoring.AuthoringSearchMatch
import com.typewritermc.types.Icon

internal fun <T : Any> PresentationBuilder<T>.subjectLayout(
    icon: PresentationValue<Icon>,
    title: com.typewritermc.presentation.PresentationExpression<String>,
) {
    adaptiveLeading(
        leading = { icon(icon) },
        center = { text(title) },
    )
}

internal fun <T : Any> PresentationBuilder<T>.authoringSubjectLayout(
    icon: PresentationValue<Icon>,
    title: com.typewritermc.presentation.PresentationExpression<String>,
    context: com.typewritermc.presentation.PresentationInputRef<AuthoringSearchContext>,
) {
    val match = context.optionalField(AuthoringSearchContext::match)
    val text = match.field(AuthoringSearchMatch::text).orElse("")
    val start = match.field(AuthoringSearchMatch::start).orElse(0)
    val end = match.field(AuthoringSearchMatch::end).orElse(0)
    adaptiveLeading(
        leading = { icon(icon) },
        center = {
            text(title)
            richText(
                PresentationTextRun(text.substring(0.presentationExpression(), start)),
                PresentationTextRun(text.substring(start, end), fontWeight = 700.0),
                PresentationTextRun(text.substring(end)),
                maxLines = 1,
                ellipsis = true,
                secondary = true,
            )
        },
    )
}
