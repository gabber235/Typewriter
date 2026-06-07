package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.NoiseGenerator
import com.typewritermc.engine.paper.entry.dialogue.currentDialogue
import com.typewritermc.engine.paper.entry.dialogue.speakersInDialogue
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.utils.logErrorIfNull
import org.bukkit.entity.Player
import java.time.Duration
import java.util.*
import kotlin.math.sin
import kotlin.time.TimeSource

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
    @Default("true")
    val headMovement: Boolean = true,
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
            headMovement,
            currentLocation,
        )
    }
}

class InDialogueActivity(
    private val dialogueIdleDuration: Duration,
    private val priority: Int,
    private val talkingActivity: Ref<out EntityActivityEntry>,
    private val idleActivity: Ref<out EntityActivityEntry>,
    private val headMovement: Boolean,
    startLocation: PositionProperty,
) : SingleChildActivity<ActivityContext>(startLocation) {
    private val trackers = mutableMapOf<UUID, PlayerDialogueTracker>()

    private val noiseGenerator = NoiseGenerator()

    private var talkingStrength = 0.0

    private var pitchAdditive = 0.0f
    private var yawAdditive = 0.0f

    private val yawAdditiveVelocity = Velocity(0f)
    private val pitchAdditiveVelocity = Velocity(0f)

    private val startMark = TimeSource.Monotonic.markNow()

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

    override fun tick(context: ActivityContext): TickResult {
        if (!headMovement) return super.tick(context)

        val elapsed = startMark.elapsedNow().inWholeMilliseconds / 1000.0

        val isTalking = child == talkingActivity

        val deltaTime = 0.05
        val targetTalkingStrength = if (isTalking) 1.0 else 0.0
        talkingStrength += (targetTalkingStrength - talkingStrength) * 3.0 * deltaTime

        val noiseSpeed = 1.8
        val lifePitch = noiseGenerator.noise(elapsed * noiseSpeed) * 10
        val lifeYaw = noiseGenerator.noise((elapsed + 100.0) * noiseSpeed) * 15

        var talkingPitch = 0.0
        var talkingYaw = 0.0
        if (talkingStrength > 0.01) {
            val nodSpeed = 15
            val nodAmplitude = 12.0
            val timeWarp = noiseGenerator.noise(elapsed * 0.4 + 500.0, 75.0) * 0.4
            val warpedTime = elapsed + timeWarp
            val nodShape = sin(warpedTime * nodSpeed) * 0.5 +
                    sin(warpedTime * nodSpeed * 2.3) * 0.15 +
                    sin(warpedTime * nodSpeed * 3.7) * 0.07
            val nodNoise = noiseGenerator.noise(elapsed * 1.8 + 600.0, 75.0) * 1.0
            talkingPitch = (nodShape + nodNoise) * nodAmplitude

            val yawShape = sin(warpedTime * 2.8) * 0.6 +
                    sin(warpedTime * 5.0) * 0.3 +
                    sin(warpedTime * 7.0) * 0.1
            val yawNoise = noiseGenerator.noise(elapsed * 3.0 + 200.0, 75.0) * 0.5
            val swayAmplitude = 6.0
            talkingYaw = (yawShape + yawNoise) * swayAmplitude
        }

        val targetYaw = (lifeYaw + talkingYaw * talkingStrength).toFloat()
        val targetPitch = (lifePitch + talkingPitch * talkingStrength).toFloat()

        yawAdditive = smoothDamp(yawAdditive, targetYaw, yawAdditiveVelocity, 0.1f, deltaTime = deltaTime.toFloat())
        pitchAdditive =
            smoothDamp(pitchAdditive, targetPitch, pitchAdditiveVelocity, 0.1f, deltaTime = deltaTime.toFloat())

        return super.tick(context)
    }

    override val currentPosition: PositionProperty
        get() = super.currentPosition.withRotation { yaw, pitch -> (yaw + yawAdditive) to (pitch + pitchAdditive) }

    override val currentProperties: List<EntityProperty>
        get() = super.currentProperties.filter { it !is PositionProperty } + currentPosition

    override fun dispose(context: ActivityContext) {
        super.dispose(context)
        yawAdditiveVelocity.value = 0f
        pitchAdditiveVelocity.value = 0f
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