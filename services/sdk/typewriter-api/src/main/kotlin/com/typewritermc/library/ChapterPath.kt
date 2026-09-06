package com.typewritermc.library

import kotlinx.serialization.Serializable

/**
 * Addresses a chapter by its dot separated path within a book.
 *
 * The empty string represents [Root]. [parse] preserves input without syntax normalization or validation.
 * Descendant checks are strict and deliberately exclude the root as an ancestor.
 */
@JvmInline
@Serializable
value class ChapterPath private constructor(
    val value: String,
) {
    val isRoot: Boolean
        get() = value.isEmpty()

    fun isDescendantOf(parent: ChapterPath): Boolean = !parent.isRoot && value.startsWith("${parent.value}.")

    /**
     * Moves this path beneath a new prefix while retaining its suffix.
     *
     * An exact match becomes [new]. Otherwise this path must be a strict descendant of [old], or the operation
     * throws.
     */
    fun replacePrefix(
        old: ChapterPath,
        new: ChapterPath,
    ): ChapterPath {
        if (this == old) return new
        require(isDescendantOf(old)) { "Chapter path $value is not inside ${old.value}." }

        val suffix = if (old.isRoot) value else value.removePrefix("${old.value}.")
        return if (new.isRoot) parse(suffix) else parse("${new.value}.$suffix")
    }

    companion object {
        val Root = ChapterPath("")

        fun parse(value: String): ChapterPath = ChapterPath(value)
    }
}
