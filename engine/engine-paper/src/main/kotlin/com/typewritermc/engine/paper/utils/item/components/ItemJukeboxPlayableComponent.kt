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
            val resolvedSound = sound.get(player, interactionContext)
            if (resolvedSound == null || resolvedSound == Sound.EMPTY) {
                meta.setJukeboxPlayable(null)
                return@editMeta
            }

            val soundKey = resolvedSound.soundId.namespacedKey ?: return@editMeta
            val jukeboxComponent = meta.jukeboxPlayable
            jukeboxComponent.songKey = soundKey
            meta.setJukeboxPlayable(jukeboxComponent)
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val expectedSound = sound.get(player, interactionContext)
        val actualComponent = item.itemMeta?.jukeboxPlayable

        if (expectedSound == null || expectedSound == Sound.EMPTY) {
            return actualComponent == null
        }

        return actualComponent?.songKey == expectedSound.soundId.namespacedKey
    }
}