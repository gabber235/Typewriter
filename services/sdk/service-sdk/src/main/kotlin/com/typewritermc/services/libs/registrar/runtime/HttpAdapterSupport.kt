package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.http.core.HttpHeaders

internal const val MAXIMUM_SKIR_BODY = 64L * 1024L
internal const val SKIR_MEDIA_TYPE = "application/octet-stream"
internal val skirRequestHeaders =
    HttpHeaders.of(
        "Content-Type" to SKIR_MEDIA_TYPE,
        "Accept" to SKIR_MEDIA_TYPE,
        "X-Typewriter-Format" to "skir-binary",
    )
internal val skirGetHeaders =
    HttpHeaders.of(
        "Accept" to SKIR_MEDIA_TYPE,
        "X-Typewriter-Format" to "skir-binary",
    )

/**
 * Recognizes the binary Skir media type case insensitively, ignoring optional content type parameters.
 *
 * Absence of the header fails the check; callers still validate status and payload separately.
 */
internal fun HttpHeaders.hasSkirMediaType(): Boolean =
    first("Content-Type")
        ?.substringBefore(';')
        ?.trim()
        ?.equals(SKIR_MEDIA_TYPE, ignoreCase = true) == true
