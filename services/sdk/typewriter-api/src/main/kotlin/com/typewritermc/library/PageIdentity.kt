package com.typewritermc.library

import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

/**
 * Identifies an authored page using a typed database key.
 *
 * The key does not include the table name; use the library reference helpers when crossing resource boundaries.
 */
@JvmInline
@Serializable
value class PageId(
    val value: ResourceId,
)

fun PageId(value: String): PageId = PageId(ResourceId(value))
