package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.Serializable

/**
 * Addresses a group in a hierarchy by its dot separated path, such as the chapter `act1.intro` of a page.
 *
 * The empty string represents [Root]. [parse] preserves input without syntax normalization or validation.
 * Descendant checks are strict and deliberately exclude the root as an ancestor. A tree layout groups resources by
 * a field of this type, and dropping a resource onto a group rewrites that field.
 */
@JvmInline
@Serializable
value class HierarchyPath(
    val value: String,
) {
    val isRoot: Boolean
        get() = value.isEmpty()

    fun isDescendantOf(parent: HierarchyPath): Boolean = !parent.isRoot && value.startsWith("${parent.value}.")

    /**
     * Moves this path beneath a new prefix while retaining its suffix.
     *
     * An exact match becomes [new]. Otherwise this path must be a strict descendant of [old], or the operation
     * throws.
     */
    fun replacePrefix(
        old: HierarchyPath,
        new: HierarchyPath,
    ): HierarchyPath {
        if (this == old) return new
        require(isDescendantOf(old)) { "Hierarchy path $value is not inside ${old.value}." }

        val suffix = if (old.isRoot) value else value.removePrefix("${old.value}.")
        return if (new.isRoot) parse(suffix) else parse("${new.value}.$suffix")
    }

    companion object {
        val Root = HierarchyPath("")

        /** Creates a path without normalizing or validating its dot separated value. */
        fun parse(value: String): HierarchyPath = HierarchyPath(value)
    }
}

/**
 * One group of a tree layout, as its header sees it: the full [path], the last path segment as [name], and the
 * [members] grouped directly under it. The host supplies this value; it is never stored.
 */
@TypewriterType(id = "c9ef8108a30f4e43805d8ee137e001dc")
data class HierarchyGroup(
    val path: HierarchyPath = HierarchyPath.Root,
    val name: String = "",
    val members: List<ResourceId> = emptyList(),
)
