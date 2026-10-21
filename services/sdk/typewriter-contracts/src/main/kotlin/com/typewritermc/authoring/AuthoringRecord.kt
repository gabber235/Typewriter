package com.typewritermc.authoring

import com.typewritermc.types.with
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordPayload
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

/*
 * A resource's authored content is the generated Skir AuthoringRecord: its type selection, kept separately from its
 * field payload so partially configured records remain editable, and its fields. A pending selection retains an
 * unfilled argument without inventing a concrete type; a complete one describes filled type arguments, not completed
 * field values or a successful catalog check. Nested nominal values still carry their own actual types.
 *
 * Record fields are kept in name order, so two records with the same fields are equal and encode to the same bytes.
 * The factory below establishes that order, and requireValid restores it for records that enter from outside.
 */

fun AuthoringRecord.Companion.of(
    configuration: TypeSelection,
    fields: Map<String, DataValue> = emptyMap(),
): AuthoringRecord =
    AuthoringRecord(
        configuration = configuration,
        fields = fields.entries.sortedBy { it.key }.map { (name, value) -> FieldValue(name = name, value = value) },
    )

/** A record with the fields of [payload], which are already in name order. */
fun AuthoringRecord.Companion.of(
    configuration: TypeSelection,
    payload: RecordPayload,
): AuthoringRecord = AuthoringRecord(configuration = configuration, fields = payload.fields)

/** The fields by name, in name order. */
val AuthoringRecord.fieldMap: Map<String, DataValue> get() = fields.associateTo(LinkedHashMap()) { it.name to it.value }

/** The fields as a record payload. */
val AuthoringRecord.payload: RecordPayload get() = RecordPayload(fields = fields)

/** Returns the value of the field named [name], or null when the record has no such field. */
fun AuthoringRecord.field(name: String): DataValue? = fields.findByKey(name)?.value

/** Returns this record with [name] set to [value], keeping the fields in name order. */
fun AuthoringRecord.with(
    name: String,
    value: DataValue,
): AuthoringRecord = copy(fields = payload.with(name, value).fields)

val TypeSelection.CompleteWrapper.use: NamedTypeUse get() = value

val TypeSelection.PendingWrapper.definition: TypeDefinitionId get() = value.definition

val TypeSelection.PendingWrapper.arguments: List<ArgumentSelection> get() = value.arguments

val ArgumentSelection.ChosenWrapper.type: TypeUse get() = value

/** The selected type, complete or pending. */
val TypeSelection.definition: TypeDefinitionId
    get() =
        when (this) {
            is TypeSelection.CompleteWrapper -> value.definition
            is TypeSelection.PendingWrapper -> value.definition
            else -> throw IllegalArgumentException("Unknown type selection variant.")
        }
