package com.typewritermc.engine.paper.utils

import com.github.retrooper.packetevents.protocol.sound.SoundCategory
import com.github.retrooper.packetevents.protocol.sound.StaticSound
import com.github.retrooper.packetevents.resources.ResourceLocation
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntitySoundEffect
import com.typewritermc.core.entries.Query
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.SoundIdEntry
import com.typewritermc.engine.paper.entry.entries.SoundSourceEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.logger
import net.kyori.adventure.sound.SoundStop
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import net.kyori.adventure.sound.Sound as AdventureSound

data class Sound(
    val soundId: SoundId = SoundId.EMPTY,
    @Help("The source of the location to play the sound from. (Defaults to player's location)")
    val soundSource: SoundSource = SelfSoundSource,
    @Help("Corresponds to the Minecraft sound category")
    val track: AdventureSound.Source = AdventureSound.Source.MASTER,
    @Help("A value of 1.0 is normal volume.")
    @InnerMin(Min(0))
    @Default("1.0")
    val volume: Var<Float> = ConstVar(1.0f),
    @Help("A value of 1.0 is normal pitch.")
    @InnerMin(Min(0))
    @InnerMax(Max(2))
    @Default("1.0")
    val pitch: Var<Float> = ConstVar(1.0f),
) {
    companion object {
        val EMPTY = Sound()
    }

    val soundStop: SoundStop?
        get() = soundId.namespacedKey?.let { SoundStop.named(it) }

    fun play(player: Player, context: InteractionContext?) {
        val key = this.soundId.namespacedKey ?: return
        val sound = AdventureSound.sound(key, track, volume.get(player, context), pitch.get(player, context))

        when (soundSource) {
            is SelfSoundSource -> player.playSound(sound)
            is EmitterSoundSource -> {
                val entryId = soundSource.entryId
                val entry = Query.findById<SoundSourceEntry>(entryId)
                if (entry == null) {
                    logger.warning("Could not find sound source entry with id $entryId")
                    return
                }

                val emitter = entry.getEmitter(player)
                val packetSound = StaticSound(ResourceLocation(key.namespace, key.key), 16f)
                val category = SoundCategory.fromId(track.ordinal)
                WrapperPlayServerEntitySoundEffect(
                    packetSound,
                    category,
                    emitter.entityId,
                    sound.volume(),
                    sound.pitch(),
                ) sendPacketTo player
            }

            is LocationSoundSource -> {
                val location = soundSource.position
                player.playSound(sound, location.x, location.y, location.z)
            }
        }
    }
}

fun Player.playSound(sound: Sound, context: InteractionContext?) = sound.play(this, context)
fun Player.stopSound(sound: Sound) = sound.soundStop?.let { this.stopSound(it) }

sealed interface SoundId {
    companion object {
        val EMPTY = DefaultSoundId(null)
    }

    val namespacedKey: NamespacedKey?
}

class DefaultSoundId(override val namespacedKey: NamespacedKey?) : SoundId {
    constructor(key: String) : this(if (key.isEmpty()) null else NamespacedKey.fromString(key))
}

class EntrySoundId(val entryId: String) : SoundId {
    override val namespacedKey: NamespacedKey?
        get() {
            val entry = Query.findById<SoundIdEntry>(entryId)
            if (entry == null) {
                logger.warning("Could not find sound entry with id $entryId")
                return null
            }
            return NamespacedKey.fromString(entry.soundId)
        }
}

sealed interface SoundSource

data object SelfSoundSource : SoundSource
class EmitterSoundSource(val entryId: String) : SoundSource

class LocationSoundSource(val position: Position) : SoundSource
