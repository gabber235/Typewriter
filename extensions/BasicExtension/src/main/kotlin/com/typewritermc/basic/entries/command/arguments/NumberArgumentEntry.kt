package com.typewritermc.basic.entries.command.arguments

import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.arguments.IntegerArgumentType
import com.mojang.brigadier.arguments.LongArgumentType
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

@Entry("number_argument", "An number argument", Colors.RED, "fa6-solid:hashtag")
@ContextKeys(NumberArgumentContextKeys::class)
/**
 * The `Number Argument` entry is an argument that takes a number.
 *
 * It only supports integers and longs.
 * In other words, it only supports numbers without a decimal point.
 */
class NumberArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Default("${Int.MIN_VALUE}")
    val min: Int = Int.MIN_VALUE,
    @Default("${Int.MAX_VALUE}")
    val max: Int = Int.MAX_VALUE,
) : ArgumentCommandArgument<Int> {
    override val type: ArgumentType<Int> get() = IntegerArgumentType.integer(min, max)
    override val klass: KClass<Int> get() = Int::class

    override fun InteractionContextBuilder.apply(value: Int) {
        set(NumberArgumentContextKeys.VALUE, value)
    }
}

enum class NumberArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Int::class)
    VALUE(Int::class),
}