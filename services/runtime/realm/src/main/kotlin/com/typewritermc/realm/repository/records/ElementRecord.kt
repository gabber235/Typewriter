package com.typewritermc.realm.repository.records

import com.surrealdb.Value
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.StoredElementValue
import com.typewritermc.elements.StoredReference
import com.typewritermc.realm.repository.utils.DataValueDatabaseCodec
import com.typewritermc.realm.repository.utils.elementPlacement
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.TypeExpression
import kotlinx.serialization.json.Json

/**
 * Keeps parsed stored elements with their database page ownership for later logical projection.
 */
internal data class StoredPageElements(
    val elements: List<StoredElement>,
    val pages: Map<com.typewritermc.elements.ElementInstanceId, com.surrealdb.RecordId>,
)

/**
 * Joins element rows with outgoing reference rows to reconstruct persistence values.
 *
 * Expected types are decoded separately from value trees. Placement discriminators must be known; logical
 * reference assembly and target existence checks happen later in the document repository.
 */
internal object ElementRecordParser {
    private val json = Json

    /**
     * Parses element rows and their outgoing reference rows as one ownership view.
     *
     * The page map is kept beside elements because callers need containment while assembling authoring documents and
     * applying element mutations. This parser does not resolve referenced targets.
     */
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
                    value =
                        StoredElementValue(
                            valueWithSlots = DataValueDatabaseCodec.decode(objectValue.get("value")),
                            references = references[id].orEmpty().map(ParsedReference::reference),
                        ),
                    placement = objectValue.get("placement").elementPlacement(),
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
}

private data class ParsedReference(
    val source: com.typewritermc.elements.ElementInstanceId,
    val reference: StoredReference,
)
