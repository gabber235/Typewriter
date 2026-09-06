package com.typewritermc.library

/**
 * Answers ancestry and link eligibility against a fixed collection of tags.
 *
 * Duplicate identities are rejected. Traversal tolerates cycles through a visited set, but missing records produce
 * an unknown ancestry result rather than a false claim.
 */
class TagHierarchy(
    tags: Collection<Tag>,
) {
    private val tagsById = tags.associateBy(Tag::id)

    init {
        require(tagsById.size == tags.size) { "Tag hierarchy ids must be unique." }
    }

    /**
     * Returns true when traversal finds [candidate] among the parents of [descendant].
     *
     * Returns null if an endpoint or a traversed record is missing. This is a parent traversal, not a reflexive
     * identity comparison.
     */
    fun isAncestor(
        candidate: TagId,
        descendant: TagId,
    ): Boolean? {
        if (candidate !in tagsById || descendant !in tagsById) return null

        val pending = ArrayDeque<TagId>()
        val visited = mutableSetOf<TagId>()
        pending += descendant
        while (pending.isNotEmpty()) {
            val currentId = pending.removeLast()
            if (!visited.add(currentId)) continue

            val current = tagsById[currentId] ?: return null
            val parentIds = current.parents.mapTo(linkedSetOf()) { it.tagId() }
            if (candidate in parentIds) return true
            pending.addAll(parentIds)
        }
        return false
    }

    /**
     * Accepts a new parent edge only when both records exist and neither is already an ancestor of the other.
     *
     * Self links, duplicate edges, cycles, redundant ancestor links, and incomplete ancestry are rejected.
     */
    fun canLink(
        child: TagId,
        parent: TagId,
    ): Boolean {
        if (child == parent) return false
        val childTag = tagsById[child] ?: return false
        if (parent !in tagsById || parent in childTag.parents.map { it.tagId() }) return false
        return isAncestor(child, parent) == false && isAncestor(parent, child) == false
    }
}
