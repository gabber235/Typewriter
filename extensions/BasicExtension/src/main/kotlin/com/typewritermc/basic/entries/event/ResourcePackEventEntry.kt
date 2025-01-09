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
@ContextKeys(ResourcePackContextKeys::class)
class ResourcePackEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),

    @Help("Which status triggers this event? (SUCCESSFULLY_LOADED by default).")
    val statusFilter: ResourcePackStatusFilter = ResourcePackStatusFilter.SUCCESSFULLY_LOADED

) : EventEntry


enum class ResourcePackStatusFilter(vararg val statuses: Status) {
    ANY(
        Status.ACCEPTED,
        Status.DECLINED,
        Status.DISCARDED,
        Status.DOWNLOADED,
        Status.FAILED_DOWNLOAD,
        Status.FAILED_RELOAD,
        Status.INVALID_URL,
        Status.SUCCESSFULLY_LOADED
    ),
    ACCEPTED(Status.ACCEPTED),
    DECLINED(Status.DECLINED),
    DISCARDED(Status.DISCARDED),
    DOWNLOADED(Status.DOWNLOADED),
    FAILED_DOWNLOAD(Status.FAILED_DOWNLOAD),
    FAILED_RELOAD(Status.FAILED_RELOAD),
    INVALID_URL(Status.INVALID_URL),
    SUCCESSFULLY_LOADED(Status.SUCCESSFULLY_LOADED);

    fun matches(eventStatus: Status) = eventStatus in statuses
}

enum class ResourcePackContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Status::class)
    STATUS(Status::class),
}

@EntryListener(ResourcePackEventEntry::class)
fun onResourcePackChange(
    event: PlayerResourcePackStatusEvent,
    query: Query<ResourcePackEventEntry>
) {
    val player = event.player
    val status = event.status

    val entries = query.findWhere { entry ->
        entry.statusFilter.matches(status)
    }.toList()

    if (entries.isEmpty()) return

    entries.triggerAllFor(player, context())
}


