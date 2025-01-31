@file:Suppress("UnstableApiUsage")

package com.typewritermc.engine.paper.command.dsl

import com.mojang.brigadier.LiteralMessage
import com.mojang.brigadier.StringReader
import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.arguments.StringArgumentType
import com.mojang.brigadier.context.CommandContext
import com.mojang.brigadier.exceptions.SimpleCommandExceptionType
import com.mojang.brigadier.suggestion.Suggestions
import com.mojang.brigadier.suggestion.SuggestionsBuilder
import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Page
import com.typewritermc.core.entries.Query
import io.papermc.paper.command.brigadier.argument.CustomArgumentType
import java.util.concurrent.CompletableFuture
import kotlin.reflect.KClass

fun StringReader.error(message: String): Nothing {
    throw SimpleCommandExceptionType(LiteralMessage(message)).createWithContext(this)
}

inline fun <S, reified E : Entry> DslCommandTree<S, *>.entry(
    name: String,
    noinline block: ArgumentBlock<S, E> = {},
) = argument(name, EntryArgumentType(E::class), E::class, block)

fun <S, E : Entry> DslCommandTree<S, *>.entry(
    name: String,
    klass: KClass<E>,
    block: ArgumentBlock<S, E> = {},
) = argument(name, EntryArgumentType(klass), klass, block)

class EntryArgumentType<E : Entry>(
    val klass: KClass<E>,
) : CustomArgumentType.Converted<E, String> {
    override fun convert(nativeType: String): E {
        return Query.findById<E>(klass, nativeType)
            ?: Query.findByName<E>(klass, nativeType)
            ?: throw SimpleCommandExceptionType(LiteralMessage("Could not find entry $nativeType")).create()
    }

    override fun getNativeType(): ArgumentType<String> = StringArgumentType.word()

    override fun <S> listSuggestions(
        context: CommandContext<S>,
        builder: SuggestionsBuilder
    ): CompletableFuture<Suggestions> {
        val input = builder.remaining
        Query.findWhere(klass) { entry ->
            entry.name.startsWith(input) || (input.length > 3 && entry.id.startsWith(input))
        }.forEach {
            builder.suggest(it.name)
        }

        return builder.buildFuture()
    }
}

fun <S> DslCommandTree<S, *>.page(
    name: String,
    type: PageType,
    block: ArgumentBlock<S, Page> = {},
) = argument(name, PageArgumentType(type), block)

class PageArgumentType(
    val type: PageType
) : CustomArgumentType.Converted<Page, String> {
    override fun convert(nativeType: String): Page {
        val pages = Query.findPagesOfType(type).toList()
        return pages.firstOrNull { it.id == nativeType || it.name == nativeType }
            ?: throw SimpleCommandExceptionType(LiteralMessage("Page '$nativeType' not found")).create()
    }

    override fun getNativeType(): ArgumentType<String> = StringArgumentType.word()

    override fun <S> listSuggestions(
        context: CommandContext<S>,
        builder: SuggestionsBuilder
    ): CompletableFuture<Suggestions> {
        val input = builder.remaining
        Query.findPagesOfType(type).filter { page ->
            page.name.startsWith(input) || (input.length > 3 && page.id.startsWith(input))
        }.forEach {
            builder.suggest(it.name)
        }
        return builder.buildFuture()
    }
}