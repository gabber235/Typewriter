package com.typewritermc.authoring

import com.typewritermc.types.namedUse
import com.typewritermc.types.with
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.ChosenArgument
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
 * field payload so partially configured records remain editable, and its fields. The selection holds only the arguments
 * a creator chose, so an unfilled one invents no concrete type; whether the chosen ones make a complete type is the
 * catalog's answer (CheckedCatalog.typeOf), not a stored state. Nested nominal values still carry their own actual types.
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
        types = emptyList(),
    )

/** A record with the fields of [payload], which are already in name order. */
fun AuthoringRecord.Companion.of(
    configuration: TypeSelection,
    payload: RecordPayload,
): AuthoringRecord = AuthoringRecord(configuration = configuration, fields = payload.fields, types = emptyList())

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

/** The selection of [use], with every argument chosen. */
fun TypeSelection.Companion.of(use: NamedTypeUse): TypeSelection =
    of(use.definition, use.arguments.withIndex().associate { it.index to it.value })

/** A selection of [definition] with the [chosen] arguments by parameter index; a parameter without one is unfilled. */
fun TypeSelection.Companion.of(
    definition: TypeDefinitionId,
    chosen: Map<Int, TypeUse> = emptyMap(),
): TypeSelection =
    TypeSelection(
        definition = definition,
        arguments = chosen.entries.sortedBy { it.key }.map { (parameter, type) -> ChosenArgument(parameter = parameter, type = type) },
    )

/** The argument a creator chose for the parameter at [parameter], or null while it is unfilled. */
fun TypeSelection.chosen(parameter: Int): TypeUse? = arguments.findByKey(parameter)?.type

/**
 * The use the chosen arguments name, in parameter order. It is the configured type only when every parameter has a
 * choice, which the catalog decides (CheckedCatalog.authoredTypeOf); read it only after asking.
 */
val TypeSelection.chosenUse: NamedTypeUse get() = definition.namedUse(arguments.map { it.type })

/** The chosen arguments by parameter index. */
val TypeSelection.chosenArguments: Map<Int, TypeUse> get() = arguments.associate { it.parameter to it.type }

/** This selection with [type] chosen for the parameter at [parameter], or that parameter unfilled when [type] is null. */
fun TypeSelection.choosing(
    parameter: Int,
    type: TypeUse?,
): TypeSelection = TypeSelection.of(definition, chosenArguments - parameter + listOfNotNull(type?.let { parameter to it }))
