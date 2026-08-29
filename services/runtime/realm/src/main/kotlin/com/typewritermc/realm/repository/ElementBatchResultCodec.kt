package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceIdSerializer
import com.typewritermc.elements.StoredElement
import com.typewritermc.library.PageId
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long

internal object ElementBatchResultCodec {
    private val json = Json { classDiscriminator = "value_kind" }

    fun encode(result: ElementBatchResult): String =
        when (result) {
            is ElementBatchResult.Success -> {
                JsonObject(
                    mapOf(
                        "kind" to JsonPrimitive("success"),
                        "elements" to JsonArray(result.elements.map(::encodeElement)),
                        "affected_pages" to JsonArray(result.affectedPages.map(::encodePageId)),
                    ),
                )
            }

            is ElementBatchResult.Conflict -> {
                JsonObject(
                    mapOf(
                        "kind" to JsonPrimitive("conflict"),
                        "conflicts" to
                            JsonArray(
                                result.conflicts.map { conflict ->
                                    JsonObject(
                                        mapOf(
                                            "id" to encodeElementId(conflict.id),
                                            "expected_revision" to JsonPrimitive(conflict.expectedRevision),
                                            "actual" to (conflict.actual?.let(::encodeElement) ?: JsonNull),
                                        ),
                                    )
                                },
                            ),
                    ),
                )
            }

            is ElementBatchResult.ValidationFailure -> {
                JsonObject(
                    mapOf(
                        "kind" to JsonPrimitive("validation_failure"),
                        "diagnostics" to
                            JsonArray(
                                result.diagnostics.map { diagnostic ->
                                    JsonObject(
                                        mapOf(
                                            "code" to JsonPrimitive(diagnostic.code),
                                            "element_id" to (diagnostic.elementId?.let(::encodeElementId) ?: JsonNull),
                                            "page_id" to (diagnostic.pageId?.let(::encodePageId) ?: JsonNull),
                                        ),
                                    )
                                },
                            ),
                    ),
                )
            }
        }.toString()

    fun decode(
        batchId: BatchId,
        value: String,
    ): ElementBatchResult {
        val root = json.parseToJsonElement(value).jsonObject
        return when (root.getValue("kind").jsonPrimitive.content) {
            "success" -> {
                ElementBatchResult.Success(
                    batchId = batchId,
                    elements = root.getValue("elements").jsonArray.map(::decodeElement),
                    affectedPages = root.getValue("affected_pages").jsonArray.mapTo(linkedSetOf(), ::decodePageId),
                )
            }

            "conflict" -> {
                ElementBatchResult.Conflict(
                    root.getValue("conflicts").jsonArray.map { valueElement ->
                        val conflict = valueElement.jsonObject
                        ElementConflict(
                            id = decodeElementId(conflict.getValue("id")),
                            expectedRevision = conflict.getValue("expected_revision").jsonPrimitive.long,
                            actual = conflict.getValue("actual").takeUnless { it is JsonNull }?.let(::decodeElement),
                        )
                    },
                )
            }

            "validation_failure" -> {
                ElementBatchResult.ValidationFailure(
                    root.getValue("diagnostics").jsonArray.map { valueElement ->
                        val diagnostic = valueElement.jsonObject
                        ElementBatchDiagnostic(
                            code = diagnostic.getValue("code").jsonPrimitive.content,
                            elementId =
                                diagnostic.getValue("element_id").takeUnless { it is JsonNull }?.let(::decodeElementId),
                            pageId = diagnostic.getValue("page_id").takeUnless { it is JsonNull }?.let(::decodePageId),
                        )
                    },
                )
            }

            else -> {
                error("Unknown stored element batch result.")
            }
        }
    }

    private fun encodeElement(value: StoredElement) = json.encodeToJsonElement(StoredElement.serializer(), value)

    private fun decodeElement(value: kotlinx.serialization.json.JsonElement) = json.decodeFromJsonElement(StoredElement.serializer(), value)

    private fun encodeElementId(value: com.typewritermc.elements.ElementInstanceId) =
        json.encodeToJsonElement(ElementInstanceIdSerializer, value)

    private fun decodeElementId(value: kotlinx.serialization.json.JsonElement) =
        json.decodeFromJsonElement(ElementInstanceIdSerializer, value)

    private fun encodePageId(value: PageId) = json.encodeToJsonElement(PageId.serializer(), value)

    private fun decodePageId(value: kotlinx.serialization.json.JsonElement) = json.decodeFromJsonElement(PageId.serializer(), value)
}
