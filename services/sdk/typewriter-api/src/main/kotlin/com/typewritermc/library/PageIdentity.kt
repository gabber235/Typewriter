package com.typewritermc.library

import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Referenceable
import kotlinx.serialization.Serializable

interface PageKind : Referenceable

@JvmInline
@Serializable
value class PageKindId(
    val value: DeclaredTypeId,
)

@Serializable
data class PageKindRef(
    val id: PageKindId,
    val revision: Int,
) {
    init {
        require(revision > 0) { "Page kind revisions must be positive." }
    }
}

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
