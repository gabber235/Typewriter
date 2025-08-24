package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.utils.Sound
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@Suppress("UnstableApiUsage")
@AlgebraicTypeInfo("jukebox_playable", Colors.RED, "fa6-solid:music")
class ItemJukeboxPlayableComponent(
    val sound: Var<Sound> = ConstVar(Sound.EMPTY)
) : ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val soundKey = sound.get(player, interactionContext)?.soundId?.namespacedKey ?: return@editMeta

            val jukeboxComponent = meta.jukeboxPlayable

            jukeboxComponent.songKey = soundKey
            meta.setJukeboxPlayable(jukeboxComponent)
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val expectedSoundKey = sound.get(player, interactionContext)?.soundId?.namespacedKey ?: return false
        val actualComponent = item.itemMeta?.jukeboxPlayable
        return actualComponent?.songKey == expectedSoundKey
    }
}