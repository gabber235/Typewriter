package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import org.bukkit.event.player.PlayerResourcePackStatusEvent
import org.bukkit.event.player.PlayerResourcePackStatusEvent.Status

/**
 * Triggers when the player's resource pack status changes.
 * You can enable triggers for ACCEPTED, DECLINED, FAILED_DOWNLOAD, or SUCCESSFULLY_LOADED.
 *
 * e.g. if 'accepted = true', then it triggers TWM entries for the ACCEPTED status.
 */
@Entry(
    "resource_pack_event",
    "Handle resource pack statuses",
    Colors.YELLOW,
    "hugeicons:file-cloud-03"
)
class ResourcePackEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),

    @Help("Trigger on ACCEPTED status")
    val accepted: Boolean = false,

    @Help("Trigger on DECLINED status")
    val declined: Boolean = false,

    @Help("Trigger on FAILED_DOWNLOAD status")
    val failedDownload: Boolean = false,

    @Help("Trigger on SUCCESSFULLY_LOADED status")
    val successfullyLoaded: Boolean = false
) : EventEntry

@EntryListener(ResourcePackEventEntry::class)
fun onResourcePackStatus(
    event: PlayerResourcePackStatusEvent,
    query: Query<ResourcePackEventEntry>
) {
    val player = event.player
    val status = event.status

    // Find all matching entries for the given status
    val entries = query.findWhere { entry ->
        when (status) {
            Status.ACCEPTED            -> entry.accepted
            Status.DECLINED            -> entry.declined
            Status.FAILED_DOWNLOAD     -> entry.failedDownload
            Status.SUCCESSFULLY_LOADED -> entry.successfullyLoaded
        }
    }.toList()

    // If no entries matched the current status, bail out
    if (entries.isEmpty()) return

    // Trigger your usual TWM logic (like with InteractEventEntry)
    entries.triggerAllFor(player, context())
}