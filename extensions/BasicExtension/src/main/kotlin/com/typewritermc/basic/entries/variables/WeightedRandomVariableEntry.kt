package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.interaction.randomSeed
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.*
import java.util.*
import java.util.Collections.emptyList
import kotlin.random.Random

@Entry(
    "weighted_random_variable",
    "A variable that returns a weighted random value of the given values",
    Colors.GREEN,
    "streamline:dices-entertainment-gaming-dices-solid",
)
@VariableData(WeightedRandomVariableData::class)
/**
 * The `WeightedRandomVariableEntry` is a variable that returns one configured value based on weight.
 *
 * ## How could this be used?
 * This can be used for loot rolls, branching dialogue, or any case where outcomes should not have equal chance.
 */
class WeightedRandomVariableEntry(
    override val id: String = "",
    override val name: String = "",
    val values: List<WeightedValue> = emptyList(),
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<WeightedRandomVariableData>()
        val dataValues = data?.values ?: emptyList()
        val allValues = (values + dataValues).filter { it.weight > 0 }

        require(allValues.isNotEmpty()) {
            "Weighted random variable '$id' has no values with a positive weight"
        }
        val interactionSeed = context.interactionContext.randomSeed()
        val seed = Objects.hash(interactionSeed, data?.hashCode() ?: hashCode())

        val selected = allValues.weightedRandom(Random(seed))
        val selectedValue = selected.value.get(context.player, context.interactionContext)
        val value = selectedValue.get(context.klass)
            ?: throw IllegalStateException(
                "Could not cast generic value ${selectedValue.data} to ${context.klass.qualifiedName}",
            )

        return value
    }
}

data class WeightedRandomVariableData(
    val values: List<WeightedValue> = emptyList(),
)

data class WeightedValue(
    val value: Var<Generic> = ConstVar(Generic.Empty),
    @Min(1)
    @Default("1")
    val weight: Int = 1,
)

private fun List<WeightedValue>.weightedRandom(random: Random): WeightedValue {
    require(isNotEmpty()) {
        "Cannot select a weighted random value from an empty list"
    }

    if (size == 1) {
        return first()
    }

    val cumulativeWeights = scan(0.0) { acc, entry -> acc + entry.weight.toDouble() }.drop(1)
    val sampledWeight = random.nextDouble() * cumulativeWeights.last()

    return zip(cumulativeWeights)
        .first { (_, cumulativeWeight) -> cumulativeWeight > sampledWeight }
        .first
}
