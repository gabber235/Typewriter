package com.typewritermc.engine.paper.entry.entries

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.entries.Entry
import com.typewritermc.engine.paper.entry.Criteria
import org.bukkit.entity.Player

@Tags("cinematic")
interface CinematicEntry : Entry {
    @Help("The criteria that must be met before this entry is shown")
    val criteria: List<Criteria>

    fun createRecording(player: Player): CinematicAction? = createSimulating(player)
    fun createSimulating(player: Player): CinematicAction? = create(player)

    fun create(player: Player): CinematicAction
}

/**
 * Primary cinematic entries may only be triggerd in the primary cinematic.
 * Not in looping cinematics.
 *
 * Most of the time it is used when only one cinematic should be played at a time.
 */
@Tags("primary_cinematic")
interface PrimaryCinematicEntry : CinematicEntry

infix fun <S : Segment> List<S>.activeSegmentAt(frame: Int) = firstOrNull { it isActiveAt frame }
infix fun <S : Segment> List<S>.canFinishAt(frame: Int): Boolean = all { it canFinishAt frame }

infix fun Segment.percentageAt(frame: Int): Double {
    val total = endFrame - startFrame
    val current = frame - startFrame
    return (current.toDouble() / total.toDouble()).coerceIn(0.0, 1.0)
}

interface Segment {
    val startFrame: Int
    val endFrame: Int
}

infix fun Segment.isActiveAt(frame: Int): Boolean = frame in startFrame..endFrame

infix fun Segment.canFinishAt(frame: Int): Boolean = frame > endFrame

val Segment.duration: Int get() = endFrame - startFrame

interface CinematicAction {
    /**
     * Called when the cinematic starts
     */
    suspend fun setup() {}

    /**
     * Called to display the cinematic at the given frame.
     * **This is not necessarily called every frame!
     * Sometimes frames are skipped to keep the cinematic timings tight**
     *
     * When the same action is used for recording, it may be that previous frames are played back.
     * If this is not possible, create a new action for recording!
     */
    suspend fun tick(frame: Int) {}

    /**
     * Called when the cinematic is finished
     */
    suspend fun teardown() {}

    /**
     * Common use case
     * ```kotlin
     * override fun canFinish(frame: Int): Boolean = entry.segments canFinishAt frame
     * ```
     */
    infix fun canFinish(frame: Int): Boolean
}

fun List<CinematicAction>.maxFrame(): Int {
    var max = 0
    while (any { !it.canFinish(max) }) {
        max++
    }
    return max
}

object EmptyCinematicAction : CinematicAction {
    override suspend fun setup() {}
    override suspend fun tick(frame: Int) {}
    override suspend fun teardown() {}
    override fun canFinish(frame: Int): Boolean = true
}