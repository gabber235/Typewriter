package com.typewritermc.expression.operations

import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.field
import com.typewritermc.types.unwrapNamed
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow

/** Realm's kernel of the map operations. Keys compare by canonical structural equality. */
internal object PortableMapKernel : MapKernel {
    override fun containsKey(
        source: List<MapRow>,
        key: DataValue,
    ): Boolean {
        val wanted = key.canonicalValueKey()
        return source.any { it.key.canonicalValueKey() == wanted }
    }

    /** A later entry with an equal key replaces the value but keeps the first row's position and identity. */
    override fun fromEntries(source: List<ListItem>): List<MapRow> {
        val rows = linkedMapOf<String, MapRow>()
        source.forEach { item ->
            val entry = item.value.unwrapNamed() as? DataValue.RecordWrapper ?: throw illTyped("Expected a map entry.")
            val key = entry.field("key") ?: throw illTyped("Expected a map entry.")
            val value = entry.field("value") ?: throw illTyped("Expected a map entry.")
            val canonical = key.canonicalValueKey()
            val earlier = rows[canonical]
            rows[canonical] = MapRow(id = earlier?.id ?: item.id, key = earlier?.key ?: key, value = value)
        }
        return rows.values.toList()
    }

    /**
     * The value of the complete row whose key equals [key], missing at that row's value while the value is unfinished.
     * Without a complete match, rows whose keys are unfinished might still match, so the result is missing at those
     * keys; otherwise the key is absent.
     */
    override fun get(
        source: Located<List<MapRow>>,
        key: DataValue,
    ): PortableMaybe<DataValue> {
        val wanted = key.canonicalValueKey()
        val match = source.value.firstOrNull { !it.key.containsUnfilled() && it.key.canonicalValueKey() == wanted }
        if (match != null) {
            if (match.value.containsUnfilled()) return PortableMaybe.Missing(listOfNotNull(source.mapValue(match.id)))
            return PortableMaybe.Value(match.value)
        }
        val unfinished = source.value.filter { it.key.containsUnfilled() }
        if (unfinished.isNotEmpty()) return PortableMaybe.Missing(unfinished.mapNotNull { source.mapKey(it.id) })
        throw OperationFailure(KernelFailure.CollectionKeyAbsent, "The map has no such key.")
    }

    override fun mapValues(
        source: List<MapRow>,
        body: List<DataValue>,
    ): List<MapRow> = source.mapIndexed { index, row -> MapRow(id = row.id, key = row.key, value = body[index]) }
}
