package com.typewritermc.engine.paper.content.modes

import com.google.common.reflect.TypeToken
import com.google.gson.Gson

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
    fun merge(next: F): F
    fun optimize(previous: F): F
    fun isEmpty(): Boolean
}

class Recorder<F : Frame<F>>(private val tape: MutableMap<Int, F> = mutableMapOf()) {
    companion object {
        fun <F : Frame<F>> create(gson: Gson, data: String): Recorder<F> {
            val map: Tape<F> = gson.fromJson(data, object : TypeToken<Tape<F>>() {}.type)
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
            val index = keys.indexOf(currentFrame)
            if (index == -1) {
                return
            }
            if (index == keys.lastIndex) {
                return
            }

            currentFrame = keys[index + 1]
            currentValue = currentValue.merge(tape[currentFrame]!!)
        }
    }
}
