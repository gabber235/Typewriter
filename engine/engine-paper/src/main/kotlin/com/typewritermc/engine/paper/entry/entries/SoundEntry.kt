package com.typewritermc.engine.paper.entry.entries

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.*
import net.kyori.adventure.sound.Sound
import org.bukkit.entity.Player

@Tags("sound_id")
interface SoundIdEntry : StaticEntry, PlaceholderEntry {
    val soundId: String

    override fun parser(): PlaceholderParser = placeholderParser {
        supply { soundId }
    }
}

@Tags("sound_source")
interface SoundSourceEntry : Entry {
    fun getEmitter(player: Player): SoundEmitter
}

class SoundEmitter(val entityId: Int)