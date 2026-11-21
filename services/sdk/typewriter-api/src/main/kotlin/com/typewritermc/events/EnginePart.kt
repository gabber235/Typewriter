package com.typewritermc.events

import kotlin.reflect.KClass

/**
 * A class an engine builds and runs, such as a source, a handler plan or a live resolver. Implementing it is the
 * registration: KSP finds every concrete implementation and generates its [EnginePartProvider], and each engine builds
 * the parts of the source parts it loaded, so a Paper part only reaches Paper.
 *
 * ```kotlin
 * class BlockBreakSource(paper: PaperEvents) : Source<BlockBreak> by
 *     paper.source<BlockBreakEvent, BlockBreak> { BlockBreak(player.protagonist) }
 * ```
 *
 * The engine builds a part from its one public constructor, asking for each parameter by type; a parameter no engine
 * part or engine service provides fails the engine's start, naming the part and the type.
 */
interface EnginePart

/**
 * Builds one [EnginePart] from its constructor. KSP generates one per concrete engine part; extensions never write one,
 * and the engine turns each into its own wiring, so an extension depends on no wiring library.
 */
interface EnginePartProvider {
    /** The part this provider builds. */
    val type: KClass<out EnginePart>

    /** Every type the part is asked for by: its supertypes, erased, including [EnginePart]. */
    val binds: List<KClass<*>>

    /** Builds the part, asking [dependencies] for each constructor parameter. */
    fun create(dependencies: EnginePartDependencies): EnginePart
}

/** What an engine gives a part's constructor. */
interface EnginePartDependencies {
    /** The one instance of [type] this engine holds; fails, naming the type, when it holds none. */
    fun <T : Any> get(type: KClass<T>): T
}
