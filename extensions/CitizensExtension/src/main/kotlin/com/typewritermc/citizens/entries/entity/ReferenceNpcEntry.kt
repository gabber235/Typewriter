package com.typewritermc.citizens.entries.entity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.StaticEntry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.Sound
import net.citizensnpcs.api.CitizensAPI
import org.bukkit.entity.Player

@Tags("reference_npc")
@Entry("reference_npc", "When the npc is not managed by TypeWriter", Colors.ORANGE, "fa-solid:user-tie")
/**
 * An identifier that references an NPC in the Citizens plugin. But does not manage the NPC.
 *
 * ## How could this be used?
 *
 * This can be used to reference an NPC which is already in the world. This could be used to create a quest that requires the player to talk to an NPC.
 */
class ReferenceNpcEntry(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @Help("The id of the NPC in the Citizens plugin.")
    val npcId: Int = 0,
) : SoundSourceEntry, SpeakerEntry, StaticEntry {
    override fun getEmitter(player: Player): SoundEmitter {
        val npc = CitizensAPI.getNPCRegistry().getById(npcId) ?: return SoundEmitter(player.entityId)
        return SoundEmitter(npc.entity?.entityId ?: player.entityId)
    }
}