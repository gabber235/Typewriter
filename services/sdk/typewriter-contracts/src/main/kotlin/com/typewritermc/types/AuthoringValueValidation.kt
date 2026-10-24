package com.typewritermc.types

import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.TypeSelection

/*
 * Checks the invariants of authored records, link occurrences and findings where they enter the runtime: from the wire
 * and from storage. Generated Skir constructors cannot enforce them, so code below these boundaries relies on values
 * that passed one of these checks. Each check fails with an IllegalArgumentException naming the rule.
 */

/**
 * Checks the selection and every field value with requirePortable and rejects a field name that appears twice.
 * Returns the canonical form: fields in name order and canonical values.
 */
fun AuthoringRecord.requireValid(): AuthoringRecord {
    val selection = configuration.requireValid()
    val checked = fields.map { field -> FieldValue(name = field.name, value = field.value.requirePortable()) }.sortedBy { it.name }
    checked.zipWithNext { previous, next -> require(previous.name != next.name) { "Record field ${next.name} is duplicated." } }
    val unchanged =
        selection === configuration && checked.indices.all { checked[it].value === fields[it].value && checked[it].name == fields[it].name }
    return if (unchanged) this else AuthoringRecord(configuration = selection, fields = checked)
}

fun TypeSelection.requireValid(): TypeSelection =
    apply {
        when (this) {
            is TypeSelection.CompleteWrapper -> {
                value.requireValid()
            }

            is TypeSelection.PendingWrapper -> {
                value.definition.requireValid()
                value.arguments.forEach { argument ->
                    when (argument) {
                        is ArgumentSelection.ChosenWrapper -> argument.value.requireValid()
                        ArgumentSelection.UNFILLED -> Unit
                        else -> throw IllegalArgumentException("Unknown argument selection variant.")
                    }
                }
            }

            else -> {
                throw IllegalArgumentException("Unknown type selection variant.")
            }
        }
    }

fun LinkOccurrenceId.requireValid(): LinkOccurrenceId =
    apply {
        endpoint.requireValid()
        location.requireValid()
    }

fun LinkOccurrence.requireValid(): LinkOccurrence =
    apply {
        id.requireValid()
        source.requireValid()
        target.requireValid()
    }

/** Checks the field owner and relative path of a finding read from outside the runtime. */
fun InitializationDiagnostic.requireValid(): InitializationDiagnostic =
    apply {
        field?.requireValid()
        relativePath?.requireValid()
    }

/** Checks the location of a problem read from outside the runtime. */
fun ValueProblem.requireValid(): ValueProblem = apply { location.requireValid() }

/** Checks the rule origin and locations of a diagnostic read from outside the runtime and rejects an unknown severity. */
fun Diagnostic.requireValid(): Diagnostic =
    apply {
        origin.requireValid()
        require(severity != DiagnosticSeverity.UNKNOWN) { "Unknown diagnostic severity." }
        primary?.requireValid()
        related.forEach { it.requireValid() }
    }
