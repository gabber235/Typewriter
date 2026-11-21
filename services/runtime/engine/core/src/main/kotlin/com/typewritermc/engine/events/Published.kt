package com.typewritermc.engine.events

import com.typewritermc.elements.Entry
import com.typewritermc.events.Event
import com.typewritermc.events.VarReader
import com.typewritermc.identity.Identity
import com.typewritermc.identity.Protagonist
import com.typewritermc.types.ResourceId
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
    private val condition: (Protagonist) -> Boolean = { true },
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
    ): List<PublishedEntry<E>> =
        all.filter { type.isInstance(it.entry) && (about == null || it.about == about) } as List<PublishedEntry<E>>

    fun entry(id: ResourceId): PublishedEntry<*>? = byId[id]

    companion object {
        /** No content: what an engine runs before its first publication. */
        val EMPTY: PublishedEntries = PublishedEntries(emptyList(), WrittenValues)
    }
}

/** Reads only written values; a computed field fails, as it does before an engine can evaluate formulas. */
object WrittenValues : VarReader {
    override fun <T> read(
        field: com.typewritermc.formula.Var<T, *>,
        candidate: com.typewritermc.events.Candidate<*>,
    ): T =
        when (field) {
            is com.typewritermc.formula.Var.Value -> field.value
            is com.typewritermc.formula.Var.Computed -> error("Field of ${candidate.entry.name} is a formula, which needs a publication.")
        }
}
