package com.typewritermc.library

import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Referenceable
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.Serializable

/**
 * Marker implemented by generated page schema types.
 *
 * A kind identifies the editor contract; [PageId] identifies an authored page instance.
 */
interface PageKind : Referenceable

/**
 * Carries the stable declared identity of a page schema, independently of its revision.
 */
@JvmInline
@Serializable
value class PageKindId(
    val value: DeclaredTypeId,
)

/**
 * Pins a page schema identity to a positive revision.
 *
 * Catalog lookups use the complete reference; sharing an identity does not imply two revisions are
 * interchangeable.
 */
@Serializable
@TypewriterType(id = "b591373727574148919d8aab4f4cd8a8")
data class PageKindRef(
    val id: PageKindId,
    val revision: Int,
) {
    init {
        require(revision > 0) { "Page kind revisions must be positive." }
    }
}

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
