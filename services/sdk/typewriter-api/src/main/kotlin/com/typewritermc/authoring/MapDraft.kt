package com.typewritermc.authoring

/**
 * Exposes authored map rows by stable row identity while keys may still be unfinished or duplicated.
 * Row access preserves those editable cases; [lookup] requires an unambiguous key match and can remain unavailable
 * when another unfinished key might also match.
 */
interface MapDraft<K, V> {
    context(reads: AuthoredReads)
    fun rows(): Availability<List<MapRowDraft<K, V>>>

    context(reads: AuthoredReads)
    fun lookup(key: K): Availability<V>
}
