package com.typewritermc.library

class TagHierarchy(
    tags: Collection<Tag>,
) {
    private val tagsById = tags.associateBy(Tag::id)

    init {
        require(tagsById.size == tags.size) { "Tag hierarchy ids must be unique." }
    }

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
