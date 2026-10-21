package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.ResourceId
import com.typewritermc.types.skir.NamedTypeUseSerializer
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** Derives stable counterpart item identities from intent without retaining operation history. */
internal fun canonicalPreparedIntentDigest(edit: PreparedEdit): String =
    frame("intents", *edit.intents.map(EditIntent::canonical).toTypedArray()).sha256Hex()

private fun EditIntent.canonical(): String =
    when (this) {
        is EditIntent.CreateResource -> {
            frame("create", canonical(ResourceId.serializer(), id), canonical(AuthoringRecord.serializer(), record))
        }

        is EditIntent.DeleteResource -> {
            frame("delete", canonical(ResourceId.serializer(), id))
        }

        is EditIntent.SetValue -> {
            frame(
                "set",
                canonical(ValueLocation.serializer(), at),
                canonical(
                    DataValue
                        .serializer(),
                    value,
                ),
            )
        }

        is EditIntent.Insert -> {
            frame(
                "insert",
                canonical(ValueLocation.serializer(), at),
                after.canonicalNullable(),
                canonical(
                    ListItem
                        .serializer(),
                    item,
                ),
            )
        }

        is EditIntent.Remove -> {
            frame("remove", canonical(ValueLocation.serializer(), at), canonical(ItemId.serializer(), item))
        }

        is EditIntent.Move -> {
            frame(
                "move",
                canonical(ValueLocation.serializer(), at),
                canonical(ItemId.serializer(), item),
                after.canonicalNullable(),
            )
        }

        is EditIntent.ConnectRelation -> {
            val value = intent
            val counterpart =
                when (val choice = value.counterpart) {
                    null -> {
                        frame("none")
                    }

                    is CounterpartChoice.Existing -> {
                        frame(
                            "existing",
                            canonical(
                                LinkOccurrence
                                    .serializer(),
                                choice.occurrence,
                            ),
                        )
                    }

                    is CounterpartChoice.New -> {
                        frame(
                            "new",
                            canonical(ValueLocation.serializer(), choice.containing),
                            canonical(
                                PreparedValue
                                    .serializer(),
                                choice.prepared,
                            ),
                        )
                    }
                }
            frame(
                "connect",
                canonical(
                    LinkOccurrence
                        .serializer(),
                    value.source,
                ),
                canonical(ResourceId.serializer(), value.target),
                counterpart,
            )
        }

        is EditIntent.DisconnectRelation -> {
            frame(
                "disconnect",
                canonical(
                    LinkOccurrenceId
                        .serializer(),
                    occurrence,
                ),
            )
        }

        is EditIntent.Retag -> {
            frame("retag", canonical(ValueLocation.serializer(), at), canonical(NamedTypeUseSerializer, type))
        }

        is EditIntent.ConfigureResource -> {
            frame(
                "configure_resource",
                canonical(ResourceId.serializer(), resource),
                canonical(
                    TypeSelection
                        .serializer(),
                    configuration,
                ),
            )
        }
    }

private fun ItemId?.canonicalNullable(): String = if (this == null) frame("none") else frame("item", canonical(ItemId.serializer(), this))

private fun frame(
    kind: String,
    vararg values: String,
): String =
    buildString {
        append(kind.length).append(':').append(kind)
        values.forEach { value -> append(value.length).append(':').append(value) }
    }

private fun <T> canonical(
    serializer: KSerializer<T>,
    value: T,
): String = authoringStorageJson.encodeToJsonElement(serializer, value).canonical().toString()

private fun JsonElement.canonical(): JsonElement =
    when (this) {
        is JsonObject -> JsonObject(entries.sortedBy { it.key }.associate { it.key to it.value.canonical() })
        is JsonArray -> JsonArray(map(JsonElement::canonical))
        is JsonPrimitive -> this
    }
