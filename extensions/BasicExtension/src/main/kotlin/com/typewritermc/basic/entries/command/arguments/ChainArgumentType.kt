package com.typewritermc.basic.entries.command.arguments

import com.mojang.brigadier.StringReader
import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.arguments.StringArgumentType
import com.mojang.brigadier.context.CommandContext
import com.mojang.brigadier.suggestion.Suggestions
import com.mojang.brigadier.suggestion.SuggestionsBuilder
import io.papermc.paper.command.brigadier.argument.CustomArgumentType
import java.util.concurrent.CompletableFuture

/**
 * A custom argument type that chains multiple argument types together.
 * This allows for parsing and suggesting multiple arguments in sequence.
 *
 * @param T The type of the result
 */
abstract class ChainArgumentType<T> : CustomArgumentType<T, String> {
    /**
     * The list of argument types to chain together.
     */
    abstract val argumentTypes: List<ArgumentType<*>>

    /**
     * Parse the chain of arguments and create the result.
     *
     * @param reader The string reader
     * @param source The command source
     * @param parsedValues The list of parsed values from each argument type
     * @return The result of parsing the chain
     */
    abstract fun <S : Any> parseChain(reader: StringReader, source: S, parsedValues: List<Any>): T

    override fun parse(reader: StringReader): T {
        throw UnsupportedOperationException("This method will never be called.")
    }

    override fun <S : Any> parse(reader: StringReader, source: S): T {
        val parsedValues = mutableListOf<Any>()

        for (i in argumentTypes.indices) {
            val argType = argumentTypes[i]

            // If this is not the first argument, expect a space
            if (i > 0) {
                if (!reader.canRead() || reader.read() != ' ') {
                    throw IllegalArgumentException("Expected a space after argument ${i}")
                }
            }

            val value = argType.parse(reader, source)
            parsedValues.add(value)
        }

        return parseChain(reader, source, parsedValues)
    }

    override fun getNativeType(): ArgumentType<String> {
        return StringArgumentType.greedyString()
    }

    override fun <S : Any> listSuggestions(
        context: CommandContext<S>,
        builder: SuggestionsBuilder
    ): CompletableFuture<Suggestions> {
        val source = context.source
        val reader = StringReader(builder.remaining)

        for (i in argumentTypes.indices) {
            val argType = argumentTypes[i]

            // If this is not the first argument, expect a space
            if (i > 0) {
                if (!reader.canRead() || reader.read() != ' ') {
                    return builder.buildFuture()
                }
            }

            if (!argType.canParse(source, reader)) {
                val nextBuilder = SuggestionsBuilder(builder.input, builder.start + reader.cursor)
                return argType.listSuggestions<S>(context, nextBuilder)
            }
        }

        return builder.buildFuture()
    }
}
