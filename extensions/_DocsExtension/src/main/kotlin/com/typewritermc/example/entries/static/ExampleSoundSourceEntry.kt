package com.typewritermc.example.entries.static

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.StaticEntry
import com.typewritermc.engine.paper.entry.entries.SoundEmitter
import com.typewritermc.engine.paper.entry.entries.SoundSourceEntry
import net.kyori.adventure.sound.Sound
import org.bukkit.entity.Player

//<code-block:sound_source_entry>
@Entry("example_sound_source", "An example sound source entry.", Colors.BLUE, "ic:round-spatial-audio-off")
class ExampleSoundSourceEntry(
    override val id: String = "",
    override val name: String = "",
) : SoundSourceEntry, StaticEntry {
    override fun getEmitter(player: Player): SoundEmitter {
        // Return the emitter that should be used for the sound.
        // An entity should be provided.
        return SoundEmitter(player.entityId)
    }
}
//</code-block:sound_source_entry>