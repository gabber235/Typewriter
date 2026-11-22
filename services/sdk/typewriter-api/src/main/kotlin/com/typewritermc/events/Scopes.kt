package com.typewritermc.events

import com.typewritermc.authoring.FieldPath
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.append
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.root
import com.typewritermc.elements.Entry
import com.typewritermc.identity.Identity
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ValuePath

/**
 * A record value inside an entry, as a handler or derive reads it: KSP generates one accessor per field of every record
 * type on `RecordScope<ThatRecord>`, so `spoken.minLines` reads the `minLines` field of the `spoken` record of the
 * scope's entry. A `Var<T, C>` field reads as a plain `T`, with its context filled from the scope; a record field gives
 * the record's own scope one level deeper. Accessors are the only path to entry values.
 */
interface RecordScope<out T> {
    /** The entry scope this record sits in; every accessor reads through its entry reader. */
    val entryScope: EntryScope<*>

    /** Where this record sits inside the entry, from the entry's root. */
    val recordPath: ValuePath
}

/**
 * What a handler or derive reads an entry through: the [entry], the [subject] it runs for and the chain's [context]. It
 * is the entry's own record scope, at the root. The engine builds every scope with its entry reader: a [Candidate] per
 * published entry a handler runs for, a [Triggered] per triggered step, and later a running step for derives.
 */
interface EntryScope<out E : Entry> : RecordScope<E> {
    val entry: E
    val subject: Identity?
    val context: Context

    /** The entry reader every accessor of this scope resolves through. */
    @GeneratedSdkApi
    val reader: EntryReader

    override val entryScope: EntryScope<E> get() = this
    override val recordPath: ValuePath get() = ValuePath.root
}

/**
 * The entry reader: the one way an accessor reaches a value of a scope's entry, at a path from the entry's root of any
 * depth. The engine resolves a plain stored value, a `Var` (written or a formula evaluated for the scope) and a nested
 * record field; where a value is stored is the reader's own concern, so a cascade of configured values plugs in there
 * without touching accessors or their callers.
 */
interface EntryReader {
    /**
     * The value at [path] in [scope]'s entry: a `Var` as its value for the scope, anything else as stored, and null
     * where nothing is stored. Throws when the value cannot be read, which fails the handler or derive reading it.
     */
    fun read(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Any?

    /**
     * Whether [scope]'s entry stores a value at [path], without reading it: a tracked read of presence only changes when
     * a value appears or goes, not when the value itself changes.
     */
    fun has(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Boolean

    /** The items of the list, set or map at [path] in [scope]'s entry, by their stable item identity, in stored order. */
    fun items(
        scope: EntryScope<*>,
        path: ValuePath,
    ): List<ItemId>
}

/**
 * A step a chain fired into, as its handler reads it: the [event] that triggered it, read through the engine's entry
 * reader. The engine builds it when it runs a handler for the event, so every Triggered can read its entry; the event
 * itself carries no reader and is what chains merge on.
 */
class Triggered<out E : Entry>(
    val event: TriggeredEvent<E>,
    @property:GeneratedSdkApi
    override val reader: EntryReader,
) : EntryScope<E> {
    override val entry: E get() = event.entry
    override val subject: Identity get() = event.subject
    override val context: Context get() = event.context

    override fun toString(): String = "Triggered(${event.entry.name}, $subject)"
}

/** The value of [field] of this record, read through the entry reader: a `Var` as its value for the scope. */
@GeneratedSdkApi
fun <V> RecordScope<*>.readField(field: FieldPath): V {
    @Suppress("UNCHECKED_CAST")
    return entryScope.reader.read(entryScope, recordPath.append(field.path)) as V
}

/** The record held by [field] of this record, as its own scope one level deeper. */
@GeneratedSdkApi
fun <R> RecordScope<*>.recordField(field: FieldPath): RecordScope<R> = RecordAt(entryScope, recordPath.append(field.path))

/** The record held by the optional [field] of this record as its own scope, or null while the record holds none. */
@GeneratedSdkApi
fun <R> RecordScope<*>.optionalRecordField(field: FieldPath): RecordScope<R>? {
    val path = recordPath.append(field.path)
    return if (entryScope.reader.has(entryScope, path)) RecordAt(entryScope, path) else null
}

/** The records of the list at [field], each as its own scope at its item, in stored order. */
@GeneratedSdkApi
fun <R> RecordScope<*>.recordList(field: FieldPath): List<RecordScope<R>> = itemsOf(field).map { RecordAt(entryScope, it) }

/** The records of the set at [field], each as its own scope at its item. */
@GeneratedSdkApi
fun <R> RecordScope<*>.recordSet(field: FieldPath): Set<RecordScope<R>> = itemsOf(field).mapTo(linkedSetOf()) { RecordAt(entryScope, it) }

/** The map at [field] with each record value as its own scope at its row, keyed by the stored key, in stored order. */
@GeneratedSdkApi
fun <K, R> RecordScope<*>.recordMap(field: FieldPath): Map<K, RecordScope<R>> =
    itemsOf(field).associate { row ->
        @Suppress("UNCHECKED_CAST")
        val key = entryScope.reader.read(entryScope, row.mapKey()) as K
        key to RecordAt(entryScope, row.mapValue())
    }

@GeneratedSdkApi
private fun RecordScope<*>.itemsOf(field: FieldPath): List<ValuePath> {
    val path = recordPath.append(field.path)
    return entryScope.reader.items(entryScope, path).map(path::item)
}

/** A record at [recordPath] inside the entry of [entryScope]. Equal scopes read the same value. */
private data class RecordAt<out T>(
    override val entryScope: EntryScope<*>,
    override val recordPath: ValuePath,
) : RecordScope<T>
