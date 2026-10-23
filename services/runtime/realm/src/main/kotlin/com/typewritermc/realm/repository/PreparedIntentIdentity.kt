package com.typewritermc.realm.repository

import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import build.skir.Serializer as SkirSerializer

/** Derives stable counterpart item identities from intent without retaining operation history. */
internal fun canonicalPreparedIntentDigest(edit: PreparedEdit): String =
    frame("intents", *edit.intents.map(EditIntent::canonical).toTypedArray()).sha256Hex()

private fun EditIntent.canonical(): String =
    when (this) {
        is EditIntent.CreateResourceWrapper -> {
            frame("create", canonical(ResourceId.serializer, value.id), canonical(AuthoringRecord.serializer, value.record))
        }

        is EditIntent.DeleteResourceWrapper -> {
            frame("delete", canonical(ResourceId.serializer, value.id))
        }

        is EditIntent.SetValueWrapper -> {
            frame(
                "set",
                canonical(ValueLocation.serializer, value.at),
                canonical(DataValue.serializer, value.value),
            )
        }

        is EditIntent.InsertWrapper -> {
            frame(
                "insert",
                canonical(ValueLocation.serializer, value.at),
                value.after.canonicalNullable(),
                canonical(ListItem.serializer, value.item),
            )
        }

        is EditIntent.RemoveWrapper -> {
            frame("remove", canonical(ValueLocation.serializer, value.at), canonical(ItemId.serializer, value.item))
        }

        is EditIntent.MoveWrapper -> {
            frame(
                "move",
                canonical(ValueLocation.serializer, value.at),
                canonical(ItemId.serializer, value.item),
                value.after.canonicalNullable(),
            )
        }

        is EditIntent.ConnectRelationWrapper -> {
            val connect = value
            val counterpart =
                when (val choice = connect.counterpart) {
                    null -> {
                        frame("none")
                    }

                    is CounterpartChoice.ExistingWrapper -> {
                        frame(
                            "existing",
                            canonical(
                                LinkOccurrence.serializer,
                                choice.value,
                            ),
                        )
                    }

                    is CounterpartChoice.NewWrapper -> {
                        frame(
                            "new",
                            canonical(ValueLocation.serializer, choice.value.containing),
                            canonical(
                                PreparedValue.serializer,
                                choice.value.prepared,
                            ),
                        )
                    }

                    else -> {
                        unknownVariant(choice)
                    }
                }
            frame(
                "connect",
                canonical(
                    LinkOccurrence.serializer,
                    connect.source,
                ),
                canonical(ResourceId.serializer, connect.target),
                counterpart,
            )
        }

        is EditIntent.DisconnectRelationWrapper -> {
            frame(
                "disconnect",
                canonical(
                    LinkOccurrenceId.serializer,
                    value,
                ),
            )
        }

        is EditIntent.RetagWrapper -> {
            frame("retag", canonical(ValueLocation.serializer, value.at), canonical(NamedTypeUse.serializer, value.type))
        }

        is EditIntent.ConfigureResourceWrapper -> {
            frame(
                "configure_resource",
                canonical(ResourceId.serializer, value.resource),
                canonical(
                    TypeSelection.serializer,
                    value.configuration,
                ),
            )
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun ItemId?.canonicalNullable(): String = if (this == null) frame("none") else frame("item", canonical(ItemId.serializer, this))

private fun frame(
    kind: String,
    vararg values: String,
): String =
    buildString {
        append(kind.length).append(':').append(kind)
        values.forEach { value -> append(value.length).append(':').append(value) }
    }

/** Skir values have one dense JSON form, so it identifies them directly. */
private fun <T> canonical(
    serializer: SkirSerializer<T>,
    value: T,
): String = serializer.toJsonCode(value)
