package com.typewritermc.engine.reading.testing

import com.typewritermc.authoring.FieldPath
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.elements.Entry
import com.typewritermc.engine.formula.EngineEvaluationEnvironment
import com.typewritermc.engine.formula.testing.DialogueEntry
import com.typewritermc.engine.formula.testing.FormulaPublication
import com.typewritermc.engine.formula.testing.aside
import com.typewritermc.engine.formula.testing.farewell
import com.typewritermc.engine.formula.testing.greeting
import com.typewritermc.engine.formula.testing.minLines
import com.typewritermc.engine.formula.testing.opens
import com.typewritermc.engine.reading.EntryLocation
import com.typewritermc.engine.reading.EntryValues
import com.typewritermc.engine.reading.Stored
import com.typewritermc.engine.reading.StoredValues
import com.typewritermc.engine.reading.TrackedEntryReader
import com.typewritermc.engine.reading.ValueLoader
import com.typewritermc.events.Context
import com.typewritermc.events.EntryReader
import com.typewritermc.events.EntryScope
import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.formula.graph.Query
import com.typewritermc.formula.graph.QueryReads
import com.typewritermc.identity.Identity
import com.typewritermc.types.ResourceId
import kotlinx.coroutines.CompletableDeferred
import java.util.concurrent.ConcurrentHashMap

/**
 * Stored values where [overrides] answer before [base]: a value, nothing, or not loaded. It stands in for whatever
 * answers at the entry reader's seam, a cascade or an engine's loaded values. A change gives a new instance.
 */
class LayeredValues(
    private val base: StoredValues,
    private val overrides: Map<EntryLocation, Stored> = emptyMap(),
) : StoredValues {
    override fun at(location: EntryLocation): Stored = overrides[location] ?: base.at(location)

    /** These values with [location] answered by [stored]. */
    fun with(
        location: EntryLocation,
        stored: Stored,
    ): LayeredValues = LayeredValues(base, overrides + (location to stored))

    /** These values with every one of [locations] not loaded. */
    fun notLoaded(vararg locations: EntryLocation): LayeredValues =
        locations.fold(this) { values, location -> values.with(location, Stored.NotLoaded) }
}

/** Loads values from [truth], each call one round, and keeps the locations of every round in order. */
class CountingLoader(
    var truth: StoredValues,
) : ValueLoader {
    val rounds: MutableList<Set<EntryLocation>> = mutableListOf()

    override suspend fun load(locations: Set<EntryLocation>): Map<EntryLocation, Stored> {
        rounds += locations
        return locations.associateWith(truth::at)
    }
}

/** Loads like [CountingLoader] from [truth], but each load first waits for [release], after telling [started]. */
class GatedLoader(
    private val truth: StoredValues,
) : ValueLoader {
    val started: CompletableDeferred<Unit> = CompletableDeferred()
    val release: CompletableDeferred<Unit> = CompletableDeferred()

    override suspend fun load(locations: Set<EntryLocation>): Map<EntryLocation, Stored> {
        started.complete(Unit)
        release.await()
        return locations.associateWith(truth::at)
    }
}

/** Counts the runs of each query the graph computes. */
class ComputeCounts : GraphListener {
    private val counts = ConcurrentHashMap<GraphKey<*>, Int>()

    override fun computed(key: GraphKey<*>) {
        counts.merge(key, 1, Int::plus)
    }

    /** How often [key] ran its compute. */
    fun of(key: GraphKey<*>): Int = counts[key] ?: 0
}

/** A scope of [entry] for [subject], read by [reader], as a running step will give a derive its receiver. */
class DeriveScope<out E : Entry>(
    override val entry: E,
    override val subject: Identity?,
    override val context: Context,
    @property:GeneratedSdkApi
    override val reader: EntryReader,
) : EntryScope<E>

/**
 * A derive of [entry] for [subject], as a running step will derive a view: the greeting while the entry opens with
 * one, otherwise the farewell. It reads only through accessors, so the graph sees exactly the branch it took.
 */
data class GreetingDerive(
    val entry: DialogueEntry,
    val subject: Identity,
) : Query<EntryValues, String> {
    context(reads: QueryReads<EntryValues>)
    override fun compute(): String {
        val scope = DeriveScope(entry, subject, Context.EMPTY, TrackedEntryReader(reads))
        return if (scope.opens) scope.greeting else scope.farewell
    }
}

/** A derive of [entry] for [subject] that asks only whether the entry holds an aside, never what the aside says. */
data class HasAsideDerive(
    val entry: DialogueEntry,
    val subject: Identity,
) : Query<EntryValues, Boolean> {
    context(reads: QueryReads<EntryValues>)
    override fun compute(): Boolean = DeriveScope(entry, subject, Context.EMPTY, TrackedEntryReader(reads)).aside != null
}

/** A derive of [entry] for [subject] that reads how many lines the entry's aside takes, or 0 without an aside. */
data class AsideLinesDerive(
    val entry: DialogueEntry,
    val subject: Identity,
) : Query<EntryValues, Int> {
    context(reads: QueryReads<EntryValues>)
    override fun compute(): Int = DeriveScope(entry, subject, Context.EMPTY, TrackedEntryReader(reads)).aside?.minLines ?: 0
}

/** Where [entry] of this publication stores [field]. */
fun EngineEvaluationEnvironment.locationOf(
    entry: Entry,
    field: FieldPath,
): EntryLocation = locationOf(entry, field.path)

/** The published entry [id] of this publication, for a scope or derive to read. */
@Suppress("UNCHECKED_CAST")
fun <E : Entry> FormulaPublication.entry(id: String): E =
    checkNotNull(entries().entry(ResourceId(id))) { "$id is not a published entry." }.entry as E
