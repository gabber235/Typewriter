package com.typewritermc.library

import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

/**
 * Identifies an authored page through its shared resource identity.
 *
 * Use the library reference helpers to select the appropriate relationship endpoint when linking resources.
 */
@JvmInline
@Serializable
value class PageId(
    val value: ResourceId,
)

fun PageId(value: String): PageId = PageId(ResourceId(value))
