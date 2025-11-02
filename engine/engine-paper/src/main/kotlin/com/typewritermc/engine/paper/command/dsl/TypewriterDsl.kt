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
import com.typewritermc.loader.Extension
import com.typewritermc.loader.ExtensionLoader
import io.papermc.paper.command.brigadier.argument.CustomArgumentType
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.concurrent.CompletableFuture
import kotlin.reflect.KClass

fun StringReader.error(message: String): Nothing {
    throw SimpleCommandExceptionType(LiteralMessage(message)).createWithContext(this)
}

typealias Predicate<T> = (T) -> Boolean

inline fun <S, reified E : Entry> DslCommandTree<S, *>.entry(
    name: String,
    noinline filter: Predicate<E> = { true },
    noinline block: ArgumentBlock<S, E> = {},
) = argument(name, EntryArgumentType(E::class, filter), E::class, block)

fun <S, E : Entry> DslCommandTree<S, *>.entry(
    name: String,
    klass: KClass<E>,
    filter: Predicate<E> = { true },
    block: ArgumentBlock<S, E> = {},
) = argument(name, EntryArgumentType(klass, filter), klass, block)

class EntryArgumentType<E : Entry>(
    val klass: KClass<E>,
    val filter: Predicate<E>,
) : CustomArgumentType.Converted<E, String> {
    override fun convert(nativeType: String): E {
        val entry = Query.findById(klass, nativeType)
            ?: Query.findByName(klass, nativeType)
            ?: throw SimpleCommandExceptionType(LiteralMessage("Could not find entry $nativeType")).create()
        if (!filter(entry)) throw SimpleCommandExceptionType(LiteralMessage("Entry did not pass filter")).create()
        return entry
    }

    override fun getNativeType(): ArgumentType<String> = StringArgumentType.word()

    override fun <S : Any> listSuggestions(
        context: CommandContext<S>,
        builder: SuggestionsBuilder
    ): CompletableFuture<Suggestions> {
        val input = builder.remaining
        Query.findWhere(klass) { entry ->
            if (!filter(entry)) return@findWhere false
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

    override fun <S : Any> listSuggestions(
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

inline fun <S, reified E : Extension> DslCommandTree<S, *>.extension(
    name: String,
    noinline block: ArgumentBlock<S, E> = {},
) = argument(name, ExtensionArgumentType(E::class), E::class, block)

fun <S, E : Extension> DslCommandTree<S, *>.extension(
    name: String,
    klass: KClass<E>,
    block: ArgumentBlock<S, E> = {},
) = argument(name, ExtensionArgumentType(klass), klass, block)

class ExtensionArgumentType<E : Extension>(
    private val klass: KClass<E>,
) : CustomArgumentType.Converted<E, String>, KoinComponent {
    private val extensionLoader by inject<ExtensionLoader>()

    override fun convert(nativeType: String): E {
        val possibleExtensions = if (nativeType.contains(":")) {
            extensionLoader.extensions.filter { it.info?.key.equals(nativeType, true) }
        } else {
            extensionLoader.extensions.filter { it.info?.name.equals(nativeType, true) }
        }

        if (possibleExtensions.isEmpty()) {
            throw SimpleCommandExceptionType(LiteralMessage("Could not find extension '$nativeType'")).create()
        }

        val possibleTypedExtensions = possibleExtensions.filterIsInstance(klass.java)

        if (possibleTypedExtensions.isEmpty()) {
            throw SimpleCommandExceptionType(LiteralMessage("Could not find extension '$nativeType' of type ${klass.qualifiedName}")).create()
        }

        if (possibleTypedExtensions.size > 1) {
            throw SimpleCommandExceptionType(LiteralMessage("Found multiple extensions '$nativeType', how the hell did you manage to do this?")).create()
        }

        return possibleTypedExtensions.first()
    }

    override fun getNativeType(): ArgumentType<String> = StringArgumentType.greedyString()

    override fun <S : Any> listSuggestions(
        context: CommandContext<S>,
        builder: SuggestionsBuilder
    ): CompletableFuture<Suggestions> {
        val input = builder.remaining
        extensionLoader.extensions.filter { extension ->
            extension.info?.let { info ->
                listOf(
                    info.name,
                    info.namespace,
                    "${info.namespace}:${info.name}"
                ).any { it.startsWith(input) }
            } ?: false
        }.forEach {
            builder.suggest("${it.info!!.namespace}:${it.info!!.name}")
        }

        return builder.buildFuture()
    }
}