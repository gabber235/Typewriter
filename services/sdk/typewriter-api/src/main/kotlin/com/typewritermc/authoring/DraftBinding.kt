package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.SnapshotId
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedType

class ReadContext(
    val snapshot: SnapshotId,
    val catalog: CatalogGeneration,
)

sealed interface DraftExpectation {
    data class Complete(
        val type: CheckedType,
    ) : DraftExpectation

    data class PartialRoot(
        val schema: PartialSchema,
    ) : DraftExpectation
}

data class DraftBinding(
    val snapshot: SnapshotId,
    val catalog: CatalogGeneration,
    val readContext: ReadContext,
    val location: ValueLocation,
    val expected: DraftExpectation,
    val actual: TypeSelection,
)

context(reads: AuthoredReads)
fun <V> DraftBinding.read(
    path: ValuePath,
    projection: ReadProjection<V>,
): Availability<V> =
    requireContext(readContext, location).flatMap {
        projection.read(location.append(path))
    }

interface ResourceDraft : DraftView {
    val id: com.typewritermc.types.ResourceId
}

interface DraftList<V> {
    context(reads: AuthoredReads)
    fun items(): Availability<List<ItemId>>

    context(reads: AuthoredReads)
    fun item(id: ItemId): Availability<V>
}

interface DraftSet<V> {
    context(reads: AuthoredReads)
    fun items(): Availability<List<ItemId>>

    context(reads: AuthoredReads)
    fun item(id: ItemId): Availability<V>
}

interface MapRowDraft<K, V> {
    val id: ItemId
    val location: ValueLocation

    context(reads: AuthoredReads)
    val key: Availability<K>

    context(reads: AuthoredReads)
    val value: Availability<V>
}

interface ReadProjection<V> {
    val expected: TypeUse

    context(reads: AuthoredReads)
    fun read(location: ValueLocation): Availability<V>
}

class ExactReadProjection<V>(
    private val codec: DraftCodec<V>,
) : ReadProjection<V> {
    override val expected: TypeUse = codec.expected

    context(reads: AuthoredReads)
    override fun read(location: ValueLocation): Availability<V> =
        reads.binding(boundPath<V>(location, expected)).flatMap { binding -> codec.read(binding) }
}

fun <V> nativeReadProjection(expected: TypeUse): ReadProjection<V> =
    object : ReadProjection<V> {
        override val expected: TypeUse = expected

        context(reads: AuthoredReads)
        override fun read(location: ValueLocation): Availability<V> = reads.read(boundPath<V>(location, expected))
    }

fun <V> representationReadProjection(
    expected: TypeUse.Named,
    representation: TypeUse,
): ReadProjection<V> =
    object : ReadProjection<V> {
        override val expected: TypeUse = expected

        context(reads: AuthoredReads)
        override fun read(location: ValueLocation): Availability<V> =
            reads.readRepresentation(boundPath<Any?>(location, expected), representation)
    }

fun <V> draftViewProjection(
    expected: TypeUse.Named,
    bind: (DraftBinding) -> V,
): ReadProjection<V> =
    object : ReadProjection<V> {
        override val expected: TypeUse = expected

        context(reads: AuthoredReads)
        override fun read(location: ValueLocation): Availability<V> = reads.binding(boundPath<V>(location, expected)).map(bind)
    }

fun <V> nullableReadProjection(inner: ReadProjection<V>): ReadProjection<V?> =
    object : ReadProjection<V?> {
        override val expected: TypeUse = TypeUse.Nullable(inner.expected)

        context(reads: AuthoredReads)
        override fun read(location: ValueLocation): Availability<V?> =
            reads.presence(boundPath<V?>(location, expected)).flatMap { present ->
                if (present) inner.read(location) else Availability.Available(null)
            }
    }

fun <V> listDraftProjection(
    expected: TypeUse.Named,
    item: ReadProjection<V>,
): ReadProjection<DraftList<V>> = collectionProjection(expected) { location, context -> ProjectedDraftList(location, context, item) }

fun <V> setDraftProjection(
    expected: TypeUse.Named,
    item: ReadProjection<V>,
): ReadProjection<DraftSet<V>> = collectionProjection(expected) { location, context -> ProjectedDraftSet(location, context, item) }

fun <K, V> mapDraftProjection(
    expected: TypeUse.Named,
    key: ReadProjection<K>,
    value: ReadProjection<V>,
): ReadProjection<MapDraft<K, V>> = collectionProjection(expected) { location, context -> ProjectedMapDraft(location, context, key, value) }

private fun <V> collectionProjection(
    expected: TypeUse.Named,
    create: (ValueLocation, ReadContext) -> V,
): ReadProjection<V> =
    object : ReadProjection<V> {
        override val expected: TypeUse = expected

        context(reads: AuthoredReads)
        override fun read(location: ValueLocation): Availability<V> =
            reads.presence(boundPath<V>(location, expected)).flatMap { present ->
                if (present) {
                    Availability.Available(create(location, reads.readContext))
                } else {
                    projectionFailure("unexpected_null", "A nonnullable collection contains null.", location)
                }
            }
    }

private class ProjectedDraftList<V>(
    override val location: ValueLocation,
    override val context: ReadContext,
    private val item: ReadProjection<V>,
) : DraftList<V>,
    ProjectedAuthoredValue {
    context(reads: AuthoredReads)
    override fun items(): Availability<List<ItemId>> =
        requireContext(context, location).map { reads.members(boundCollectionPath(location)) }

    context(reads: AuthoredReads)
    override fun item(id: ItemId): Availability<V> = requireContext(context, location).flatMap { item.read(location.item(id)) }
}

private class ProjectedDraftSet<V>(
    override val location: ValueLocation,
    override val context: ReadContext,
    private val item: ReadProjection<V>,
) : DraftSet<V>,
    ProjectedAuthoredValue {
    context(reads: AuthoredReads)
    override fun items(): Availability<List<ItemId>> =
        requireContext(context, location).map { reads.members(boundCollectionPath(location)) }

    context(reads: AuthoredReads)
    override fun item(id: ItemId): Availability<V> = requireContext(context, location).flatMap { item.read(location.item(id)) }
}

private class ProjectedMapDraft<K, V>(
    override val location: ValueLocation,
    override val context: ReadContext,
    private val key: ReadProjection<K>,
    private val value: ReadProjection<V>,
) : MapDraft<K, V>,
    ProjectedAuthoredValue {
    context(reads: AuthoredReads)
    override fun rows(): Availability<List<MapRowDraft<K, V>>> =
        requireContext(context, location).map {
            reads.members(boundCollectionPath(location)).map { id ->
                ProjectedMapRow(location, context, id, key, value)
            }
        }

    context(reads: AuthoredReads)
    override fun lookup(key: K): Availability<V> {
        requireContext(context, location).let { available ->
            if (available !is Availability.Available) return available.cast()
        }
        val authoredKey = key.authoredKey(this.key)
        if (authoredKey is Availability.Failed) return authoredKey
        if (authoredKey is Availability.Unavailable) return authoredKey
        val matches = mutableListOf<MapRowDraft<K, V>>()
        val unavailable = mutableListOf<ValueLocation>()
        val rows = rows()
        if (rows !is Availability.Available) return rows.cast()
        for (row in rows.value) {
            val candidate =
                if (authoredKey is Availability.Available) {
                    reads
                        .canonicalValueKey(boundPath<Any?>(row.location.mapKey(), this.key.expected))
                        .map { it == authoredKey.value }
                } else {
                    row.key.map { it == key }
                }
            when (candidate) {
                is Availability.Available -> if (candidate.value) matches += row
                is Availability.Unavailable -> unavailable += candidate.locations
                is Availability.Failed -> return candidate
            }
        }
        if (matches.size > 1) {
            return Availability.Unavailable(matches.map(MapRowDraft<K, V>::location))
        }
        if (matches.size == 1) {
            return if (unavailable.isEmpty()) {
                matches.single().value
            } else {
                Availability.Unavailable((matches.map(MapRowDraft<K, V>::location) + unavailable).distinct())
            }
        }
        return if (unavailable.isEmpty()) {
            Availability.Unavailable(listOf(location))
        } else {
            Availability.Unavailable(unavailable.distinct())
        }
    }
}

private class ProjectedMapRow<K, V>(
    parent: ValueLocation,
    override val context: ReadContext,
    override val id: ItemId,
    private val keyProjection: ReadProjection<K>,
    private val valueProjection: ReadProjection<V>,
) : MapRowDraft<K, V>,
    ProjectedAuthoredValue {
    override val location = parent.item(id)

    context(reads: AuthoredReads)
    override val key: Availability<K>
        get() = requireContext(context, location).flatMap { keyProjection.read(location.mapKey()) }

    context(reads: AuthoredReads)
    override val value: Availability<V>
        get() = requireContext(context, location).flatMap { valueProjection.read(location.mapValue()) }
}

private interface ProjectedAuthoredValue {
    val context: ReadContext
    val location: ValueLocation
}

context(reads: AuthoredReads)
private fun <K> K.authoredKey(projection: ReadProjection<K>): Availability<String>? =
    when (this) {
        is DraftView -> {
            requireContext(readContext, location).flatMap {
                reads.canonicalValueKey(boundPath<Any?>(location, projection.expected))
            }
        }

        is ProjectedAuthoredValue -> {
            requireContext(context, location).flatMap {
                reads.canonicalValueKey(boundPath<Any?>(location, projection.expected))
            }
        }

        else -> {
            null
        }
    }

context(reads: AuthoredReads)
private fun requireContext(
    expected: ReadContext,
    location: ValueLocation,
): Availability<Unit> =
    if (reads.readContext === expected) {
        Availability.Available(Unit)
    } else {
        projectionFailure(
            "read_context_mismatch",
            "The draft view belongs to a different snapshot or catalog generation.",
            location,
        )
    }

@Suppress("UNCHECKED_CAST")
private fun <V> Availability<*>.cast(): Availability<V> = this as Availability<V>

private fun ValueLocation.item(id: ItemId): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapValue))

private fun <V> projectionFailure(
    code: String,
    message: String,
    location: ValueLocation,
): Availability<V> = Availability.Failed(EvaluationDiagnostic(code, message, listOf(location)))

class GenericField<Owner>(
    val owner: TypeDefinitionId,
    val path: ValuePath,
    val template: TypeTemplate,
)

fun ValueLocation.append(relative: ValuePath): ValueLocation = copy(path = ValuePath(path.segments + relative.segments))
