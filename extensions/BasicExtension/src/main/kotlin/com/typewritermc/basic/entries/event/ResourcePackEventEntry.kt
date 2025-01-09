package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import org.bukkit.event.player.PlayerResourcePackStatusEvent
import org.bukkit.event.player.PlayerResourcePackStatusEvent.Status
import kotlin.reflect.KClass

@Entry(
    "resource_pack_event",
    "When the player's resource pack status changes",
    Colors.YELLOW,
    "mingcute:file-cloud-fill"
)
class ResourcePackEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),

    @Help("List of resource pack statuses that will trigger this event.")
    @Default("""["SUCCESSFULLY_LOADED"]""")
    val statuses: List<Status> = listOf(Status.SUCCESSFULLY_LOADED)

) : EventEntry

@EntryListener(ResourcePackEventEntry::class)
fun onResourcePackChange(event: PlayerResourcePackStatusEvent, query: Query<ResourcePackEventEntry>) {
    val eventStatus = event.status

    val entries = query.findWhere { entry -> eventStatus in entry.statuses }.toList()

    if (entries.isEmpty()) return

    entries.triggerAllFor(event.player, context())
}