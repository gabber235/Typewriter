package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.engine.paper.utils.playSound

@Entry("play_sound", "Play sound at player, or location", Colors.RED, "fa6-solid:volume-high")
/**
 * The `Play Sound Action` is an action that plays a sound for the player. This action provides you with the ability to play any sound that is available in Minecraft, at a specified location.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations. You can use it to provide audio feedback to players, such as when they successfully complete a challenge, or to create ambiance in your Minecraft world, such as by playing background music or sound effects. The possibilities are endless!
 */
class PlaySoundActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val sound: Var<Sound> = ConstVar(Sound.EMPTY),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        player.playSound(sound.get(player, context), context)
    }
}