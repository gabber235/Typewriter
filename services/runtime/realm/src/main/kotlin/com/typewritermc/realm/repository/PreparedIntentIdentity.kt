package com.typewritermc.realm.repository

import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.services.libs.utils.sha256Hex
import com.typewritermc.types.toSkir
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import build.skir.Serializer as SkirSerializer
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

/** Derives stable counterpart item identities from intent without retaining operation history. */
internal fun canonicalPreparedIntentDigest(edit: PreparedEdit): String =
    frame("intents", *edit.intents.map(EditIntent::canonical).toTypedArray()).sha256Hex()

private fun EditIntent.canonical(): String =
    when (this) {
        is EditIntent.CreateResource -> {
            frame("create", canonical(SkirResourceId.serializer, id.toSkir()), canonical(AuthoringRecord.serializer, record))
        }

        is EditIntent.DeleteResource -> {
            frame("delete", canonical(SkirResourceId.serializer, id.toSkir()))
        }

        is EditIntent.SetValue -> {
            frame(
                "set",
                canonical(ValueLocation.serializer, at),
                canonical(DataValue.serializer, value),
            )
        }

        is EditIntent.Insert -> {
            frame(
                "insert",
                canonical(ValueLocation.serializer, at),
                after.canonicalNullable(),
                canonical(ListItem.serializer, item),
            )
        }

        is EditIntent.Remove -> {
            frame("remove", canonical(ValueLocation.serializer, at), canonical(ItemId.serializer, item))
        }

        is EditIntent.Move -> {
            frame(
                "move",
                canonical(ValueLocation.serializer, at),
                canonical(ItemId.serializer, item),
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
                                LinkOccurrence.serializer,
                                choice.occurrence,
                            ),
                        )
                    }

                    is CounterpartChoice.New -> {
                        frame(
                            "new",
                            canonical(ValueLocation.serializer, choice.containing),
                            canonical(
                                PreparedValue.serializer,
                                choice.prepared,
                            ),
                        )
                    }
                }
            frame(
                "connect",
                canonical(
                    LinkOccurrence.serializer,
                    value.source,
                ),
                canonical(SkirResourceId.serializer, value.target.toSkir()),
                counterpart,
            )
        }

        is EditIntent.DisconnectRelation -> {
            frame(
                "disconnect",
                canonical(
                    LinkOccurrenceId.serializer,
                    occurrence,
                ),
            )
        }

        is EditIntent.Retag -> {
            frame("retag", canonical(ValueLocation.serializer, at), canonical(NamedTypeUse.serializer, type))
        }

        is EditIntent.ConfigureResource -> {
            frame(
                "configure_resource",
                canonical(SkirResourceId.serializer, resource.toSkir()),
                canonical(
                    TypeSelection.serializer,
                    configuration,
                ),
            )
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
