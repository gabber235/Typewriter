package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.security.MessageDigest

/** Derives stable counterpart item identities from intent without retaining operation history. */
internal fun canonicalPreparedIntentDigest(edit: PreparedEdit): String =
    frame("intents", *edit.intents.map(EditIntent::canonical).toTypedArray()).sha256()

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(toByteArray()).joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }

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
                    com.typewritermc.types.DataValue
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
                    com.typewritermc.types.ListItem
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
                                com.typewritermc.authoring.LinkOccurrence
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
                                com.typewritermc.authoring.PreparedValue
                                    .serializer(),
                                choice.prepared,
                            ),
                        )
                    }
                }
            frame(
                "connect",
                canonical(
                    com.typewritermc.authoring.LinkOccurrence
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
                    com.typewritermc.authoring.LinkOccurrenceId
                        .serializer(),
                    occurrence,
                ),
            )
        }

        is EditIntent.Retag -> {
            frame("retag", canonical(ValueLocation.serializer(), at), canonical(TypeUse.Named.serializer(), type))
        }

        is EditIntent.ConfigureResource -> {
            frame(
                "configure_resource",
                canonical(ResourceId.serializer(), resource),
                canonical(
                    com.typewritermc.authoring.TypeSelection
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
