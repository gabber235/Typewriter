package com.typewritermc.types

import skirout.editor.v1.catalog.InputAnswer
import skirout.editor.v1.catalog.PreparationDraft
import skirout.editor.v1.catalog.PreparationOperation
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.RequiredInput
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.type_catalog.CatalogGeneration

/*
 * Checks the value preparation requests, continuations and prepared values the editor sends where they enter the
 * runtime. Each check fails with an IllegalArgumentException naming the rule and returns the canonical form: authored
 * values and records in canonical notation and field order. A value that is already canonical is returned as is.
 */

fun CatalogGeneration.requireValid(): CatalogGeneration = apply { require(value.isNotBlank()) { "Catalog generation must not be blank." } }

fun PreparationTarget.requireValid(): PreparationTarget =
    apply {
        when (this) {
            is PreparationTarget.ValueWrapper -> value.requireValid()
            is PreparationTarget.RecordWrapper -> value.requireValid()
            else -> throw IllegalArgumentException("Preparation target is unknown.")
        }
    }

fun ValuePreparationRequest.requireValid(): ValuePreparationRequest {
    catalog.requireValid()
    target.requireValid()
    val supplied = suppliedValue?.requirePortable()
    return if (supplied === suppliedValue) this else copy(suppliedValue = supplied)
}

fun PreparedContent.requireValid(): PreparedContent =
    when (this) {
        is PreparedContent.ValueWrapper -> value.requirePortable().let { if (it === value) this else PreparedContent.ValueWrapper(it) }
        is PreparedContent.RecordWrapper -> value.requireValid().let { if (it === value) this else PreparedContent.RecordWrapper(it) }
        else -> throw IllegalArgumentException("Prepared content is unknown.")
    }

fun PreparedValue.requireValid(): PreparedValue {
    findings.forEach { it.requireValid() }
    val checked = content.requireValid()
    return if (checked === content) this else copy(content = checked)
}

fun RequiredInput.requireValid(): RequiredInput =
    apply {
        path.requireValid()
        expected.requireValid()
    }

fun InputAnswer.requireValid(): InputAnswer {
    path.requireValid()
    val checked = value.requirePortable()
    return if (checked === value) this else copy(value = checked)
}

/** Also rejects a pending default path that appears twice. */
fun PreparationDraft.requireValid(): PreparationDraft {
    catalog.requireValid()
    target.requireValid()
    pendingDefaults.forEach { it.requireValid() }
    require(pendingDefaults.toSet().size == pendingDefaults.size) { "A pending default path is duplicated." }
    requiredInputs.forEach { it.requireValid() }
    findings.forEach { it.requireValid() }
    val checked = content.requireValid()
    return if (checked === content) this else copy(content = checked)
}

fun PreparationOperation.requireValid(): PreparationOperation =
    when (this) {
        is PreparationOperation.StartWrapper -> {
            value.requireValid().let { if (it === value) this else PreparationOperation.StartWrapper(it) }
        }

        is PreparationOperation.ResumeWrapper -> {
            PreparationOperation.createResume(draft = value.draft.requireValid(), answers = value.answers.map { it.requireValid() })
        }

        else -> {
            throw IllegalArgumentException("Unknown preparation operation.")
        }
    }
