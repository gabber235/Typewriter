package com.typewritermc.engine.events

import com.typewritermc.authoring.FieldPath
import com.typewritermc.elements.Entry
import com.typewritermc.engine.formula.EngineEvaluationEnvironment
import com.typewritermc.engine.formula.FormulaReadException
import com.typewritermc.engine.runtime.CompiledResourceGraph
import com.typewritermc.events.Candidate
import com.typewritermc.events.Event
import com.typewritermc.events.VarReader
import com.typewritermc.formula.Var
import com.typewritermc.identity.Engine
import com.typewritermc.identity.Identity
import com.typewritermc.identity.Protagonist
import com.typewritermc.library.Book
import com.typewritermc.library.BookFields
import com.typewritermc.library.Page
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toResourceId
import java.util.concurrent.atomic.AtomicBoolean
import java.util.logging.Level
import java.util.logging.Logger
import kotlin.reflect.KClass

/**
 * One published entry as handlers see it: [priority] is inherited from its page, [about] is the event its type argument
 * names (`CancelableEventEntry<BlockBreak>` is about `BlockBreak`), and its book's condition decides whom it applies to.
 */
class PublishedEntry<out E : Entry>(
    val id: ResourceId,
    val entry: E,
    val priority: Int,
    val about: KClass<out Event>? = null,
    private val condition: (Protagonist) -> Boolean,
) {
    /** Whether the entry's book applies to [subject]; a subject that is no protagonist, or none, always applies. */
    fun appliesTo(subject: Identity?): Boolean = subject !is Protagonist || condition(subject)
}

/** The entries of one publication, with the reader that evaluates their `Var` fields. */
class PublishedEntries(
    entries: List<PublishedEntry<*>>,
    val reader: VarReader,
) {
    private val byId = entries.associateBy { it.id }
    private val all = entries

    /** The published entries of [type]; with [about], only those about that event. */
    @Suppress("UNCHECKED_CAST")
    fun <E : Entry> entries(
        type: KClass<E>,
        about: KClass<out Event>? = null,
    ): List<PublishedEntry<E>> = all.filter { type.isInstance(it.entry) && (about == null || it.about == about) } as List<PublishedEntry<E>>

    fun entry(id: ResourceId): PublishedEntry<*>? = byId[id]

    companion object {
        /** No content: what an engine runs before its first publication. */
        val EMPTY: PublishedEntries = PublishedEntries(emptyList(), Unpublished)
    }
}

/** The reader before the first publication, which has no entries whose fields it could read. */
private object Unpublished : VarReader {
    override fun read(
        field: FieldPath,
        candidate: Candidate<*>,
    ): Any? = error("${candidate.entry.name} is read before any publication.")
}

/**
 * The entries of [graph] as handlers see them on [engine]: each with its page's priority, the event its type argument
 * names, and its book's condition, read through [environment].
 */
@Suppress("UNCHECKED_CAST")
fun publishedEntries(
    graph: CompiledResourceGraph,
    environment: EngineEvaluationEnvironment,
    engine: Engine,
): PublishedEntries {
    val conditions = hashMapOf<ResourceId?, (Protagonist) -> Boolean>()
    return PublishedEntries(
        graph.elements.mapNotNull { (key, element) ->
            val entry = element as? Entry ?: return@mapNotNull null
            val page = graph.resource(entry.page.target) as? Page
            val about = graph.typeArguments[key].orEmpty().firstOrNull { Event::class.java.isAssignableFrom(it.java) }
            val book = page?.book?.target
            val condition = conditions.getOrPut(book) { bookCondition(graph, book, environment, engine) }
            PublishedEntry(key.source.toResourceId(), entry, page?.priority ?: 0, about as KClass<out Event>?, condition)
        },
        environment,
    )
}

/**
 * Whom the book [id] applies to: a written condition at once, a formula evaluated per protagonist with it as
 * `protagonist` and [engine] as `engine`. A book that is not in the publication, or whose condition fails to evaluate,
 * applies to nobody, the conservative choice, and logs one warning per publication.
 */
private fun bookCondition(
    graph: CompiledResourceGraph,
    id: ResourceId?,
    environment: EngineEvaluationEnvironment,
    engine: Engine,
): (Protagonist) -> Boolean {
    val warned = AtomicBoolean(false)
    val nobody = { reason: String, failure: Throwable? ->
        if (warned.compareAndSet(false, true)) log.log(Level.WARNING, "Book ${id?.value} applies to nobody: $reason", failure)
        false
    }
    val book = id?.let(graph::resource) as? Book ?: return { nobody("it is not in the publication.", null) }
    return when (val condition = book.condition) {
        is Var.Value -> { _ -> condition.value }

        is Var.Computed -> { protagonist ->
            try {
                environment.evaluate(id, BookFields.condition, mapOf(PROTAGONIST to protagonist, ENGINE to engine)) as Boolean
            } catch (failure: FormulaReadException) {
                nobody("its condition failed.", failure)
            }
        }
    }
}

private const val PROTAGONIST = "protagonist"
private const val ENGINE = "engine"

private val log: Logger = Logger.getLogger(PublishedEntries::class.java.name)
