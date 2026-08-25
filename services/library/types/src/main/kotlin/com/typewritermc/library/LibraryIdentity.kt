package com.typewritermc.library

import kotlinx.serialization.Serializable

@JvmInline
@Serializable
value class BookId(
    val key: RecordIdKey,
) {
    constructor(value: String) : this(RecordIdKey.String(value))
}

@JvmInline
@Serializable
value class TagId(
    val key: RecordIdKey,
) {
    constructor(value: String) : this(RecordIdKey.String(value))
}

@JvmInline
@Serializable
value class ResourceRevision(
    val value: Long,
) {
    init {
        require(value >= 1) { "Resource revisions must be positive." }
    }
}

@JvmInline
@Serializable
value class LibraryRevision(
    val value: Long,
) {
    init {
        require(value >= 1) { "Library revisions must be positive." }
    }
}

@JvmInline
@Serializable
value class LibraryName(
    val value: String,
)
