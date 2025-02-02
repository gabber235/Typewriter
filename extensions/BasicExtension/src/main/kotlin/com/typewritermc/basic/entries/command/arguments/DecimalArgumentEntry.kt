package com.typewritermc.basic.entries.command.arguments

import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.arguments.DoubleArgumentType
import com.typewritermc.basic.entries.command.ArgumentCommandArgument
import com.typewritermc.basic.entries.command.CommandArgumentEntry
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionContextBuilder
import com.typewritermc.engine.paper.entry.TriggerableEntry
import kotlin.reflect.KClass

@Entry("decimal_argument", "A double-precision floating-point argument", Colors.RED, "material-symbols:decimal-increase-rounded")
@ContextKeys(DecimalArgumentContextKeys::class)
/**
 * The `Decimal Argument` entry is an argument that takes a decimal.
 *
 * It supports both doubles and floats.
 */
class DecimalArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Default("${Double.MIN_VALUE}")
    val min: Double = Double.MIN_VALUE,
    @Default("${Double.MAX_VALUE}")
    val max: Double = Double.MAX_VALUE,
) : ArgumentCommandArgument<Double> {
    override val type: ArgumentType<Double> get() = DoubleArgumentType.doubleArg(min, max)
    override val klass: KClass<Double> get() = Double::class

    override fun InteractionContextBuilder.apply(value: Double) {
        set(DecimalArgumentContextKeys.VALUE, value)
    }
}

enum class DecimalArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Double::class)
    VALUE(Double::class),
}