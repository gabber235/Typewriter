package com.typewritermc.realm.repository.records

import com.surrealdb.Value
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.StoredElementValue
import com.typewritermc.elements.StoredReference
import com.typewritermc.realm.repository.utils.DataValueDatabaseCodec
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.TypeExpression
import kotlinx.serialization.json.Json

internal data class StoredPageElements(
    val elements: List<StoredElement>,
    val pages: Map<com.typewritermc.elements.ElementInstanceId, com.surrealdb.RecordId>,
)

internal object ElementRecordParser {
    private val json = Json

    fun parse(
        elementsValue: Value,
        referencesValue: Value,
    ): StoredPageElements {
        val references =
            referencesValue.getArray().map(::parseReference).groupBy { it.source }
        val pages = linkedMapOf<com.typewritermc.elements.ElementInstanceId, com.surrealdb.RecordId>()
        val elements =
            elementsValue.getArray().map { value ->
                val objectValue = value.getObject()
                val id = objectValue.get("id").getRecordId().toElementInstanceId()
                pages[id] = objectValue.get("page").getRecordId()
                StoredElement(
                    id = id,
                    elementType = ElementTypeId(DeclaredTypeId.parse(objectValue.get("element_type").getString())),
                    schemaRevision = objectValue.get("schema_revision").getLong().toInt(),
                    name = objectValue.get("name").getString(),
                    value =
                        StoredElementValue(
                            valueWithSlots = DataValueDatabaseCodec.decode(objectValue.get("value")),
                            references = references[id].orEmpty().map(ParsedReference::reference),
                        ),
                    placement = parsePlacement(objectValue.get("placement")),
                )
            }
        return StoredPageElements(elements, pages)
    }

    private fun parseReference(value: Value): ParsedReference {
        val objectValue = value.getObject()
        return ParsedReference(
            source = objectValue.get("in").getRecordId().toElementInstanceId(),
            reference =
                StoredReference(
                    slot = ReferenceSlotId(objectValue.get("slot").getString()),
                    target = objectValue.get("out").getRecordId().toResourceId(),
                    expectedType =
                        json.decodeFromString(
                            TypeExpression.serializer(),
                            objectValue.get("expected_type").getString(),
                        ),
                ),
        )
    }

    private fun parsePlacement(value: Value): ElementPlacement {
        val placement = value.getObject()
        return when (val kind = placement.get("kind").getString()) {
            "graph_v1" -> {
                ElementPlacement.Graph(
                    x = placement.get("x").getLong().toInt(),
                    y = placement.get("y").getLong().toInt(),
                    width = placement.get("width").getLong().toInt(),
                    height = placement.get("height").getLong().toInt(),
                )
            }

            "timeline_entry_v1" -> {
                ElementPlacement.TimelineEntry(placement.get("track_index").getLong().toInt())
            }

            "timeline_segment_v1" -> {
                ElementPlacement.TimelineSegment(
                    startFrame = placement.get("start_frame").getLong().toInt(),
                    endFrame = placement.get("end_frame").getLong().toInt(),
                )
            }

            "timeline_keyframe_v1" -> {
                ElementPlacement.TimelineKeyframe(placement.get("frame").getLong().toInt())
            }

            else -> {
                error("Unknown element placement kind '$kind'.")
            }
        }
    }
}

private data class ParsedReference(
    val source: com.typewritermc.elements.ElementInstanceId,
    val reference: StoredReference,
)
