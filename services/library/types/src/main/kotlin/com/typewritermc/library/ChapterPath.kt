package com.typewritermc.library

import kotlinx.serialization.Serializable

@JvmInline
@Serializable
value class ChapterPath private constructor(
    val value: String,
) {
    val isRoot: Boolean
        get() = value.isEmpty()

    fun isDescendantOf(parent: ChapterPath): Boolean = !parent.isRoot && value.startsWith("${parent.value}.")

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
