package com.typewritermc.authoring

interface MapDraft<K, V> {
    context(reads: AuthoredReads)
    fun rows(): Availability<List<MapRowDraft<K, V>>>

    context(reads: AuthoredReads)
    fun lookup(key: K): Availability<V>
}
