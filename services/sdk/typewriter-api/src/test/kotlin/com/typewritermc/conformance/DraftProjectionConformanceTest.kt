package com.typewritermc.conformance

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.DraftView
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.MapDraft
import com.typewritermc.authoring.PartialSchema
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.draftViewProjection
import com.typewritermc.authoring.listDraftProjection
import com.typewritermc.authoring.mapDraftProjection
import com.typewritermc.authoring.nativeReadProjection
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TagDraftType
import com.typewritermc.types.DataValue
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.canonicalValueKey
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.math.BigInteger

val DraftProjectionConformanceTest by testSuite {
    test("generated nested drafts preserve partial fields and reject another immutable read view") {
        val resource = ResourceId("draft:tag")
        val root = ValueLocation(resource, ValuePath())
        val placement = root.field("placement")
        val placementUse = com.typewritermc.authoring.GraphPlacementDefinition.use
        val generation = CatalogGeneration("draft catalog")
        val original =
            FixtureDraftReads(
                generation,
                mapOf(
                    placement to
                        DataValue.Named(
                            placementUse,
                            DataValue.Record(
                                mapOf(
                                    "x" to DataValue.Integer(BigInteger.valueOf(7)),
                                    "y" to DataValue.Unfilled,
                                    "width" to DataValue.Integer(BigInteger.ONE),
                                    "height" to DataValue.Integer(BigInteger.ONE),
                                ),
                            ),
                        ),
                    placement.field("x") to DataValue.Integer(BigInteger.valueOf(7)),
                    placement.field("y") to DataValue.Unfilled,
                ),
            )
        val staged = FixtureDraftReads(generation, original.values)
        val binding =
            DraftBinding(
                generation,
                original.readContext,
                root,
                DraftExpectation.PartialRoot(PartialSchema(emptyList(), emptyList(), emptyList())),
                TypeSelection.Complete(TagDefinition.use),
            )
        val tag = TagDraftType.bind(binding)

        val nested = with(original) { (tag.placement as Availability.Available).value }
        with(original) {
            nested.x shouldBe Availability.Available(7)
            nested.y shouldBe Availability.Unavailable(listOf(placement.field("y")))
        }
        with(staged) {
            (nested.x as Availability.Failed).diagnostic.code shouldBe "read_context_mismatch"
        }
    }

    test("collection projections retain item identity and their captured read view") {
        val root = ValueLocation(ResourceId("draft:list"), ValuePath())
        val first = ItemId("first")
        val listUse = TypeUse.Named(StandardTypes.list, listOf(INT_USE))
        val reads =
            FixtureDraftReads(
                CatalogGeneration("list catalog"),
                mapOf(
                    root to DataValue.Named(listUse, DataValue.ListValue(listOf(ListItem(first, DataValue.Integer(BigInteger.TEN))))),
                    root.item(first) to DataValue.Integer(BigInteger.TEN),
                ),
                mapOf(root to listOf(first)),
            )
        val projection = listDraftProjection(listUse, nativeReadProjection<Int>(INT_USE))
        val draft = with(reads) { (projection.read(root) as Availability.Available).value }

        with(reads) {
            draft.items() shouldBe Availability.Available(listOf(first))
            draft.item(first) shouldBe Availability.Available(10)
        }
        val newer = FixtureDraftReads(reads.catalog, reads.values, mapOf(root to listOf(first)))
        with(newer) {
            (draft.items() as Availability.Failed).diagnostic.code shouldBe "read_context_mismatch"
            (draft.item(first) as Availability.Failed).diagnostic.code shouldBe "read_context_mismatch"
        }
    }

    test("map draft lookup compares authored record meaning and reports duplicate ambiguity as unavailable") {
        val root = ValueLocation(ResourceId("draft:map"), ValuePath())
        val first = ItemId("first")
        val duplicate = ItemId("duplicate")
        val unique = ItemId("unique")
        val unfinished = ItemId("unfinished")
        val keyUse = TypeUse.Named(FIXTURE_KEY_ID, emptyList())
        val mapUse = TypeUse.Named(StandardTypes.map, listOf(keyUse, TEXT_USE))
        val meaningfulKey = DataValue.Named(keyUse, DataValue.Record(mapOf("code" to DataValue.StringValue("same"))))
        val uniqueKey = DataValue.Named(keyUse, DataValue.Record(mapOf("code" to DataValue.StringValue("unique"))))
        val reads =
            FixtureDraftReads(
                CatalogGeneration("map catalog"),
                mapOf(
                    root to
                        DataValue.Named(
                            mapUse,
                            DataValue.MapValue(
                                listOf(
                                    MapRow(first, meaningfulKey, DataValue.StringValue("first value")),
                                    MapRow(duplicate, meaningfulKey, DataValue.StringValue("duplicate value")),
                                    MapRow(unique, uniqueKey, DataValue.StringValue("unique value")),
                                    MapRow(unfinished, DataValue.Unfilled, DataValue.StringValue("unfinished value")),
                                ),
                            ),
                        ),
                    root.item(first).mapKey() to meaningfulKey,
                    root.item(first).mapValue() to DataValue.StringValue("first value"),
                    root.item(duplicate).mapKey() to meaningfulKey,
                    root.item(duplicate).mapValue() to DataValue.StringValue("duplicate value"),
                    root.item(unique).mapKey() to uniqueKey,
                    root.item(unique).mapValue() to DataValue.StringValue("unique value"),
                    root.item(unfinished).mapKey() to DataValue.Unfilled,
                    root.item(unfinished).mapValue() to DataValue.StringValue("unfinished value"),
                ),
                mapOf(root to listOf(first, duplicate, unique, unfinished)),
            )
        val keyProjection = draftViewProjection(keyUse, ::FixtureKeyDraft)
        val projection: com.typewritermc.authoring.ReadProjection<MapDraft<FixtureKeyDraft, String>> =
            mapDraftProjection(mapUse, keyProjection, nativeReadProjection(TEXT_USE))
        val draft = with(reads) { (projection.read(root) as Availability.Available).value }
        val rows = with(reads) { (draft.rows() as Availability.Available).value }
        val key = with(reads) { (rows.first().key as Availability.Available).value }
        val uniqueDraft = with(reads) { (rows.single { it.id == unique }.key as Availability.Available).value }

        with(reads) {
            draft.lookup(key) shouldBe
                Availability.Unavailable(
                    listOf(root.item(first), root.item(duplicate)),
                )
            draft.lookup(uniqueDraft) shouldBe
                Availability.Unavailable(
                    listOf(root.item(unique), root.item(unfinished).mapKey()),
                )
        }
    }
}

private class FixtureKeyDraft(
    private val binding: DraftBinding,
) : DraftView {
    override val catalog = binding.catalog
    override val readContext = binding.readContext
    override val location = binding.location
    override val actualType = Availability.Available((binding.actual as TypeSelection.Complete).use)
}

private class FixtureDraftReads(
    override val catalog: CatalogGeneration,
    val values: Map<ValueLocation, DataValue>,
    private val collectionMembers: Map<ValueLocation, List<ItemId>> = emptyMap(),
) : AuthoredReads {
    override val readContext = ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.Unfilled || value == DataValue.Null) return Availability.Unavailable(listOf(path.location))
        val native: Any =
            when (val payload = value.unwrapNamed()) {
                is DataValue.Integer -> payload.value.intValueExact()
                is DataValue.StringValue -> payload.value
                is DataValue.Boolean -> payload.value
                else -> return failed("unsupported_fixture_read", path.location)
            }
        @Suppress("UNCHECKED_CAST")
        return Availability.Available(native as T)
    }

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> {
        @Suppress("UNCHECKED_CAST")
        return read(path as BoundPath<T>)
    }

    override fun presence(path: BoundPath<*>): Availability<Boolean> =
        when (values[path.location]) {
            null, DataValue.Unfilled -> Availability.Unavailable(listOf(path.location))
            DataValue.Null -> Availability.Available(false)
            else -> Availability.Available(true)
        }

    override fun binding(path: BoundPath<*>): Availability<DraftBinding> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.Unfilled || value == DataValue.Null) return Availability.Unavailable(listOf(path.location))
        val named = value as? DataValue.Named ?: return failed("expected_named_binding", path.location)
        return Availability.Available(
            DraftBinding(
                catalog,
                readContext,
                path.location,
                DraftExpectation.PartialRoot(PartialSchema(emptyList(), emptyList(), emptyList())),
                TypeSelection.Complete(named.actualType),
            ),
        )
    }

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.Unfilled || value == DataValue.Null) return Availability.Unavailable(listOf(path.location))
        return Availability.Available(value.canonicalValueKey())
    }

    override fun members(path: BoundCollectionPath): List<ItemId> = collectionMembers[path.location].orEmpty()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Selections are outside this fixture.")
}

private fun DataValue.unwrapNamed(): DataValue = if (this is DataValue.Named) payload else this

private fun <T> failed(
    code: String,
    location: ValueLocation,
): Availability<T> = Availability.Failed(EvaluationDiagnostic(code, code, listOf(location)))

private fun ValueLocation.field(name: String): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.item(id: ItemId): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapValue))

private val INT_USE = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
private val TEXT_USE = TypeUse.Scalar(ScalarKind.Text)
private val FIXTURE_KEY_ID = TypeDefinitionId(TypeId.Qualified("test", "DraftKey"), 1)
