package com.typewritermc.operations

import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.library.BookDraftProjection
import com.typewritermc.library.PageDraftProjection
import com.typewritermc.types.ResourceId

/** Transfers ownership and appends moved pages within their unchanged chapters. */
context(session: OperationPreparation)
internal suspend fun movePagesToBook(
    targets: List<ResourceId>,
    destination: ResourceId,
) {
    val selected = targets.map { requireAuthored(PageDraftProjection.read(ValueLocation(it, ValuePath()))) }
    val moving = selected.filter { requireAuthored(it.book).target != destination }
    if (moving.isEmpty()) return

    val chapters = moving.associate { it.id to requireAuthored(it.chapter) }
    val destinationBook = requireAuthored(BookDraftProjection.read(ValueLocation(destination, ValuePath())))
    val members = requireAuthored(destinationBook.pages)
    val priorities = mutableMapOf<String, Int>()
    requireAuthored(members.items()).forEach { member ->
        val peer = requireAuthored(PageDraftProjection.read(ValueLocation(requireAuthored(members.item(member)).target, ValuePath())))
        if (peer.id in chapters) return@forEach
        val chapter = requireAuthored(peer.chapter)
        if (chapter !in chapters.values) return@forEach
        val priority = requireAuthored(peer.priority)
        priorities[chapter] = priorities[chapter]?.coerceAtLeast(priority) ?: priority
    }

    val assignments =
        moving.map { page ->
            val chapter = chapters.getValue(page.id)
            val previous = priorities[chapter]
            require(previous != Int.MAX_VALUE) { "The destination chapter has no remaining page priority." }
            val next = previous?.plus(1) ?: 0
            priorities[chapter] = next
            page to next
        }
    session.relations.requireMove(moving, destination, session.invocation.origin, session.choices).apply()
    assignments.forEach { (page, priority) -> page.setPriority(priority) }
}
