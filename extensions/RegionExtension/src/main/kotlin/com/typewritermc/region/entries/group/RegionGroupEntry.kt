package com.typewritermc.region.entries.group

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.Group
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.GroupId
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.RegionReferenceData
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent

@Entry("region_members_group", "All players grouped by the region they are in", Colors.MYRTLE_GREEN, "fa6-solid:object-group")
/**
 * Groups players by the region they are currently inside, so facts using this group are
 * shared by everyone in the same region. A player counts as inside as soon as any part of
 * their body overlaps the region.
 *
 * Membership is answered from where the player stands at the moment the fact is read, with
 * none of the boundary inset the enter and leave events use. Somebody standing exactly on the
 * edge can therefore flip in and out of the group between two reads, and while they are out
 * their reads answer zero and their writes go nowhere. Draw the region so its boundary is not
 * where players stand still.
 *
 * A player inside none of the configured regions has no group, and fact reads and writes
 * do nothing for them. A player inside several configured regions belongs to the first one
 * in the list.
 *
 * ## How could this be used?
 *
 * Store the state of a boss fight per arena, so every player inside sees the same phase.
 * Or count lever pulls in a puzzle room as one shared fact for the party inside.
 */
class RegionGroupEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Regions to group by. A player inside several belongs to the first match.")
    val definitions: List<Ref<RegionDefinitionEntry>> = emptyList(),
) : GroupEntry {
    override fun groupId(player: Player): GroupId? {
        val engine: RegionEngine = KoinJavaComponent.get(RegionEngine::class.java)
        for (definition in definitions) {
            val tracker = engine.query(RegionReferenceData(definition), player) ?: continue
            if (tracker.isInside(player)) return GroupId(definition.id)
        }
        return null
    }

    /**
     * The engine's roster rather than the server's own list, which is a live view over the list
     * the server mutates when someone joins or leaves. A fact is read wherever a criteria is
     * evaluated, which is not always the main thread, and walking that view from another one
     * throws as soon as anybody connects.
     */
    override fun group(id: GroupId): Group {
        val engine: RegionEngine = KoinJavaComponent.get(RegionEngine::class.java)
        return Group(engine.onlinePlayers().filter { groupId(it) == id })
    }
}
