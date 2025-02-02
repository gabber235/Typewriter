package com.typewritermc.basic.entries.command.arguments

import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.arguments.StringArgumentType
import com.typewritermc.basic.entries.command.ArgumentCommandArgument
import com.typewritermc.basic.entries.command.CommandArgumentEntry
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionContextBuilder
import com.typewritermc.engine.paper.entry.TriggerableEntry
import kotlin.reflect.KClass

@Entry("word_argument", "A single word argument", Colors.RED, "fa6-solid:font")
@ContextKeys(WordArgumentContextKeys::class)
/**
 * The `Word Argument` entry is an argument that takes a single word.
 */
class WordArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ArgumentCommandArgument<String> {
    override val type: ArgumentType<String> get() = StringArgumentType.word()
    override val klass: KClass<String> get() = String::class

    override fun InteractionContextBuilder.apply(value: String) {
        set(WordArgumentContextKeys.VALUE, value)
    }
}

enum class WordArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(String::class)
    VALUE(String::class)
}

@Entry("string_argument", "A string argument", Colors.RED, "bxs:quote-right")
@ContextKeys(StringArgumentContextKeys::class)
/**
 * The `String Argument` entry is an argument that takes a string.
 * If spaces are needed, one must wrap it in quotes.
 */
class StringArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ArgumentCommandArgument<String> {
    override val type: ArgumentType<String> get() = StringArgumentType.string()
    override val klass: KClass<String> get() = String::class

    override fun InteractionContextBuilder.apply(value: String) {
        set(StringArgumentContextKeys.VALUE, value)
    }
}

enum class StringArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(String::class)
    VALUE(String::class)
}

@Entry("greedy_string_argument", "A greedy string argument", Colors.RED, "fa6-solid:text-width")
@ContextKeys(GreedyStringArgumentContextKeys::class)
/**
 * The `Greedy String Argument` entry is an argument that takes a greedy string.
 * This means that it will take as many words as possible.
 * This can only be the last argument in the command.
 */
class GreedyStringArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ArgumentCommandArgument<String> {
    override val type: ArgumentType<String> get() = StringArgumentType.greedyString()
    override val klass: KClass<String> get() = String::class

    override fun InteractionContextBuilder.apply(value: String) {
        set(GreedyStringArgumentContextKeys.VALUE, value)
    }
}

enum class GreedyStringArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(String::class)
    VALUE(String::class)
}