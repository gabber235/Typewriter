package com.typewritermc.engine.paper.content.modes

import com.google.gson.Gson
import com.google.gson.JsonParser
import kotlin.reflect.KClass

/**
 * Tape is a map of ticks to values.
 * It is used to store the values of a recorder over time.
 *
 * The idea is that the recorder will store the values of the capturer in a tape every tick.
 * But only when the value changes.
 *
 * @param F The type of the values in the tape
 */
typealias Tape<F> = Map<Int, F>

interface Frame<F : Frame<F>> {
    /**
     * Merge the previous (this) frame with the next frame to reverse the optimizations.
     */
    fun merge(next: F): F

    /**
     * Clean the frame.
     * This can be used when the optimization determined no frame was needed here but some data still needs to be removed.
     */
    fun clean(): F

    /**
     * Optimize the current frame based on the previous frame.
     * This is used to reduce the size of the tape by removing unnecessary frames.
     * Or unnecessary data in the frame.
     */
    fun optimize(previous: F): F

    /**
     * Check if the frame is empty.
     * This is used to determine if the frame should be added to the tape.
     */
    fun isEmpty(): Boolean
}

fun <F : Frame<F>> parseTape(gson: Gson, klass: KClass<F>, data: String): Tape<F> {
    val reader = JsonParser.parseString(data)
    val objectReader = reader.asJsonObject
    val map: Tape<F> = objectReader.asMap()
        .mapKeys { it.key.toString().toInt() }
        .mapValues { gson.fromJson(it.value, klass.java) }
    return map
}

class Recorder<F : Frame<F>>(private val tape: MutableMap<Int, F> = mutableMapOf()) {
    companion object {
        fun <F : Frame<F>> create(gson: Gson, klass: KClass<F>, data: String): Recorder<F> {
            val map = parseTape(gson, klass, data)

            val flatten = mutableMapOf<Int, F>()
            val frames = map.keys.sorted()
            val streamer = Streamer(map)
            for (frame in frames) {
                flatten[frame] = streamer.frame(frame)
            }
            return Recorder(flatten)
        }
    }

    fun record(frame: Int, value: F) {
        tape[frame] = value
    }

    operator fun get(frame: Int): F? {
        return tape.filter { it.key <= frame }.maxByOrNull { it.key }?.value
    }

    fun resetFramesAfter(startFrame: Int) {
        tape.keys.retainAll { it < startFrame }
    }

    fun buildAndOptimize(): Tape<F> {
        val frames = tape.keys.sorted()
        val optimized = mutableMapOf<Int, F>()
        for (i in frames.indices) {
            val frame = frames[i]
            val currentValue = tape[frame]!!
            val previous = frames.getOrNull(i - 1)
            if (previous == null) {
                optimized[frame] = currentValue
                continue
            }
            val previousValue = tape[previous]!!
            val optimizedValue = currentValue.optimize(previousValue)
            if (optimizedValue.isEmpty()) {
                continue
            }
            optimized[frame] = optimizedValue
        }
        return optimized
    }
}

class Streamer<F : Frame<F>>(private val tape: Tape<F>) {
    private val keys = tape.keys.sorted()
    private var currentFrame = keys.first()
    private var currentValue: F = tape[currentFrame]!!

    init {
        assert(tape.isNotEmpty())
    }

    fun frame(frame: Int): F {
        if (frame < currentFrame) {
            resetPlayer()
        }
        forwardUntil(frame)
        return currentValue
    }

    fun currentFrame(): F = currentValue

    operator fun get(frame: Int): F = frame(frame)

    private fun resetPlayer() {
        currentFrame = keys.first()
        currentValue = tape[currentFrame]!!
    }

    private fun forwardUntil(frame: Int) {
        while (currentFrame < frame) {
            currentFrame++
            val nextFrame = tape[currentFrame]
            currentValue = if (nextFrame == null) {
                currentValue.clean()
            } else {
                currentValue.merge(nextFrame)
            }
        }
    }
}
