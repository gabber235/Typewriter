@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.conformance

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.DraftView
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.MapDraft
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.draftViewProjection
import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.listDraftProjection
import com.typewritermc.authoring.mapDraftProjection
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.nativeReadProjection
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.use
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TagDraftType
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.actualType
import com.typewritermc.types.bigInteger
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.field
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import java.math.BigInteger

val DraftProjectionConformanceTest by testSuite {
    test("generated nested drafts preserve partial fields and reject another immutable read view") {
        val resource = ResourceId("draft:tag")
        val root = ValueLocation.of(resource)
        val placement = root.field("placement")
        val placementUse = com.typewritermc.authoring.GraphPlacementDefinition.use
        val generation = CatalogGeneration(value = "draft catalog")
        val original =
            FixtureDraftReads(
                generation,
                mapOf(
                    placement to
                        DataValue.named(
                            placementUse,
                            DataValue.record(
                                mapOf(
                                    "x" to DataValue.integer(BigInteger.valueOf(7)),
                                    "y" to DataValue.UNFILLED,
                                    "width" to DataValue.integer(BigInteger.ONE),
                                    "height" to DataValue.integer(BigInteger.ONE),
                                ),
                            ),
                        ),
                    placement.field("x") to DataValue.integer(BigInteger.valueOf(7)),
                    placement.field("y") to DataValue.UNFILLED,
                ),
            )
        val staged = FixtureDraftReads(generation, original.values)
        val binding =
            DraftBinding(
                generation,
                original.readContext,
                root,
                DraftExpectation.PartialRoot(
                    PartialSchema(knownFields = emptyList(), dependentFields = emptyList(), pendingArguments = emptyList()),
                ),
                TypeSelection.CompleteWrapper(TagDefinition.use),
            )
        val tag = TagDraftType.bind(binding)

        val nested = with(original) { (tag.placement as Availability.Available).value }
        with(original) {
            nested.x shouldBe Availability.Available(7)
            nested.y shouldBe Availability.Unavailable(listOf(placement.field("y")))
        }
        with(staged) {
            (nested.x as Availability.Failed).diagnostic.failure.value shouldBe "read_context_mismatch"
        }
    }

    test("collection projections retain item identity and their captured read view") {
        val root = ValueLocation.of(ResourceId("draft:list"))
        val first = ItemId(value = "first")
        val listUse = StandardTypes.list.namedUse(listOf(INT_USE))
        val reads =
            FixtureDraftReads(
                CatalogGeneration(value = "list catalog"),
                mapOf(
                    root to
                        DataValue.named(
                            listUse,
                            DataValue.listValue(listOf(ListItem(id = first, value = DataValue.integer(BigInteger.TEN)))),
                        ),
                    root.item(first) to DataValue.integer(BigInteger.TEN),
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
            (draft.items() as Availability.Failed).diagnostic.failure.value shouldBe "read_context_mismatch"
            (draft.item(first) as Availability.Failed).diagnostic.failure.value shouldBe "read_context_mismatch"
        }
    }

    test("map draft lookup compares authored record meaning and reports duplicate ambiguity as unavailable") {
        val root = ValueLocation.of(ResourceId("draft:map"))
        val first = ItemId(value = "first")
        val duplicate = ItemId(value = "duplicate")
        val unique = ItemId(value = "unique")
        val unfinished = ItemId(value = "unfinished")
        val keyUse = FIXTURE_KEY_ID.namedUse(emptyList())
        val mapUse = StandardTypes.map.namedUse(listOf(keyUse.use, TEXT_USE))
        val meaningfulKey = DataValue.named(keyUse, DataValue.record(mapOf("code" to DataValue.StringValueWrapper("same"))))
        val uniqueKey = DataValue.named(keyUse, DataValue.record(mapOf("code" to DataValue.StringValueWrapper("unique"))))
        val reads =
            FixtureDraftReads(
                CatalogGeneration(value = "map catalog"),
                mapOf(
                    root to
                        DataValue.named(
                            mapUse,
                            DataValue.mapValue(
                                listOf(
                                    MapRow(id = first, key = meaningfulKey, value = DataValue.StringValueWrapper("first value")),
                                    MapRow(id = duplicate, key = meaningfulKey, value = DataValue.StringValueWrapper("duplicate value")),
                                    MapRow(id = unique, key = uniqueKey, value = DataValue.StringValueWrapper("unique value")),
                                    MapRow(
                                        id = unfinished,
                                        key = DataValue.UNFILLED,
                                        value = DataValue.StringValueWrapper("unfinished value"),
                                    ),
                                ),
                            ),
                        ),
                    root.item(first).mapKey() to meaningfulKey,
                    root.item(first).mapValue() to DataValue.StringValueWrapper("first value"),
                    root.item(duplicate).mapKey() to meaningfulKey,
                    root.item(duplicate).mapValue() to DataValue.StringValueWrapper("duplicate value"),
                    root.item(unique).mapKey() to uniqueKey,
                    root.item(unique).mapValue() to DataValue.StringValueWrapper("unique value"),
                    root.item(unfinished).mapKey() to DataValue.UNFILLED,
                    root.item(unfinished).mapValue() to DataValue.StringValueWrapper("unfinished value"),
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
    override val actualType = Availability.Available((binding.actual as TypeSelection.CompleteWrapper).use)
}

private class FixtureDraftReads(
    override val catalog: CatalogGeneration,
    val values: Map<ValueLocation, DataValue>,
    private val collectionMembers: Map<ValueLocation, List<ItemId>> = emptyMap(),
) : AuthoredReads {
    override val readContext = ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return Availability.Unavailable(listOf(path.location))
        val native: Any =
            when (val payload = value.unwrapNamed()) {
                is DataValue.IntegerWrapper -> payload.bigInteger.intValueExact()
                is DataValue.StringValueWrapper -> payload.value
                is DataValue.BooleanWrapper -> payload.value
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
            null, DataValue.UNFILLED -> Availability.Unavailable(listOf(path.location))
            DataValue.NULL -> Availability.Available(false)
            else -> Availability.Available(true)
        }

    override fun binding(path: BoundPath<*>): Availability<DraftBinding> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return Availability.Unavailable(listOf(path.location))
        val named = value as? DataValue.NamedWrapper ?: return failed("expected_named_binding", path.location)
        return Availability.Available(
            DraftBinding(
                catalog,
                readContext,
                path.location,
                DraftExpectation.PartialRoot(
                    PartialSchema(knownFields = emptyList(), dependentFields = emptyList(), pendingArguments = emptyList()),
                ),
                TypeSelection.CompleteWrapper(named.actualType),
            ),
        )
    }

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return Availability.Unavailable(listOf(path.location))
        return Availability.Available(value.canonicalValueKey())
    }

    override fun members(path: BoundCollectionPath): List<ItemId> = collectionMembers[path.location].orEmpty()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Selections are outside this fixture.")
}

private fun <T> failed(
    code: String,
    location: ValueLocation,
): Availability<T> =
    Availability.Failed(
        EvaluationDiagnostic(
            failure =
                skirout.editor.v1.expression
                    .FailureId(value = code),
            message = code,
            locations = listOf(location),
        ),
    )

private val INT_USE = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
private val TEXT_USE = ScalarKind.TEXT.use
private val FIXTURE_KEY_ID = TypeDefinitionId.qualified("test", "DraftKey")
