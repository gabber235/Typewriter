package com.typewritermc.library

import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Referenceable
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
    val key: RecordIdKey,
) {
    constructor(value: String) : this(
        com.typewritermc.types.RecordIdKey
            .String(value),
    )
}
