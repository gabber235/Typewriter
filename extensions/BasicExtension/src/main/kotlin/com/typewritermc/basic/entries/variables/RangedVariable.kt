package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import java.time.Duration
import kotlin.math.roundToInt
import kotlin.random.Random
import kotlin.reflect.safeCast

@Entry("ranged_variable", "A variable which returns a random value in a range", Colors.GREEN, "mdi:code-tags")
@GenericConstraint(Int::class)
@GenericConstraint(Double::class)
@GenericConstraint(Duration::class)
@VariableData(RangedVariableData::class)
class RangedVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<RangedVariableData>()
            ?: throw IllegalStateException("Could not find data for ${context.klass}, data: ${context.data} for entry $id")
        when (context.klass) {
            Int::class -> {
                val start = data.range.start.get(Int::class) ?: 0
                val end = data.range.endInclusive.get(Int::class) ?: 0
                val step = data.step.get(Int::class) ?: 1

                val numberOfSteps = (end - start) / step + 1
                val randomStep = Random.nextInt(numberOfSteps)
                val value = start + randomStep * step
                return context.klass.safeCast(value)!!
            }

            Double::class -> {
                val start = data.range.start.get(Double::class) ?: 0.0
                val end = data.range.endInclusive.get(Double::class) ?: 0.0
                val step = data.step.get(Double::class) ?: 1.0

                val numberOfSteps = (((end - start) / step) + 1).roundToInt()
                val randomStep = Random.nextInt(numberOfSteps)
                val value = start + randomStep * step
                return context.klass.safeCast(value)!!
            }

            Duration::class -> {
                val start = data.range.start.get(Duration::class) ?: Duration.ZERO
                val end = data.range.endInclusive.get(Duration::class) ?: Duration.ZERO
                val step = data.step.get(Duration::class) ?: Duration.ZERO

                val startNanos = start.toNanos()
                val endNanos = end.toNanos()
                val stepNanos = step.toNanos()

                val numberOfSteps = ((endNanos - startNanos) / stepNanos + 1).toInt()
                val randomStep = Random.nextInt(numberOfSteps)
                val value = startNanos + randomStep * stepNanos
                return context.klass.safeCast(Duration.ofNanos(value))!!
            }

            else -> throw IllegalStateException("Could not find data for ${context.klass}, data: ${context.data} for entry $id")
        }
    }
}

data class RangedVariableData(
    val range: ClosedRange<Generic>,
    val step: Generic,
)