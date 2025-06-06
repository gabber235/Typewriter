package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.dialogue.currentDialogue
import com.typewritermc.engine.paper.entry.dialogue.speakersInDialogue
import com.typewritermc.engine.paper.entry.entity.ActivityContext
import com.typewritermc.engine.paper.entry.entity.EntityActivity
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entity.SingleChildActivity
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.utils.logErrorIfNull
import org.bukkit.entity.Player
import java.time.Duration
import java.util.*

@Entry("in_dialogue_activity", "An in dialogue activity", Colors.PALATINATE_BLUE, "bi:chat-square-quote-fill")
/**
 * The `InDialogueActivityEntry` is an activity that activates child activities when a player is in a dialogue with the NPC.
 *
 * The activity will only activate when the player is in a dialogue with the NPC.
 *
 * ## How could this be used?
 * This can be used to stop a npc from moving when a player is in a dialogue with it.
 */
class InDialogueActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Default("30000")
    @Help("When a player is considered to be idle in the same dialogue")
    /**
     * The duration a player can be idle in the same dialogue before the activity deactivates.
     *
     * When set to 0, it won't use the timer.
     *
     * <Admonition type="info">
     *     When the dialogue priority is higher than this activity's priority, this timer will be ignored.
     *     And will only exit when the dialogue is finished.
     * </Admonition>
     */
    val dialogueIdleDuration: Duration = Duration.ofSeconds(30),
    @Help("The activity that will be used when the npc is in a dialogue")
    val talkingActivity: Ref<out EntityActivityEntry> = emptyRef(),
    @Help("The activity that will be used when the npc is not in a dialogue")
    val idleActivity: Ref<out EntityActivityEntry> = emptyRef(),
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        return InDialogueActivity(
            dialogueIdleDuration,
            priority,
            talkingActivity,
            idleActivity,
            currentLocation,
        )
    }
}

class InDialogueActivity(
    private val dialogueIdleDuration: Duration,
    private val priority: Int,
    private val talkingActivity: Ref<out EntityActivityEntry>,
    private val idleActivity: Ref<out EntityActivityEntry>,
    startLocation: PositionProperty,
) : SingleChildActivity<ActivityContext>(startLocation) {
    private val trackers = mutableMapOf<UUID, PlayerDialogueTracker>()

    override fun currentChild(context: ActivityContext): Ref<out EntityActivityEntry> {
        val definition =
            context.instanceRef.get()?.definition.logErrorIfNull("Could not find definition, this should not happen. Please report this on the TypeWriter Discord!")
                ?: return idleActivity
        val inDialogue = context.viewers.filter { viewer ->
            viewer.speakersInDialogue.any {
                it == definition || it == context.instanceRef
            }
        }

        trackers.keys.removeIf { uuid -> inDialogue.none { it.uniqueId == uuid } }

        if (inDialogue.isEmpty()) {
            return idleActivity
        }

        inDialogue.forEach { player ->
            trackers.computeIfAbsent(player.uniqueId) { PlayerDialogueTracker(player.currentDialogue) }.update(player)
        }

        val isTalking = trackers.any { (_, tracker) -> tracker.isActive(dialogueIdleDuration) }
        return if (isTalking) {
            talkingActivity
        } else {
            idleActivity
        }
    }

    private inner class PlayerDialogueTracker(
        var dialogue: DialogueEntry?,
        var lastInteraction: Long = System.currentTimeMillis()
    ) {
        fun update(player: Player) {
            val currentDialogue = player.currentDialogue
            if (dialogue?.id == currentDialogue?.id) return
            lastInteraction = System.currentTimeMillis()
            dialogue = currentDialogue
        }

        fun isActive(maxIdleDuration: Duration): Boolean {
            if (maxIdleDuration.isZero) return true
            val dialogue = dialogue ?: return false
            if (dialogue.priority > priority) return true
            return System.currentTimeMillis() - lastInteraction < maxIdleDuration.toMillis()
        }
    }
}