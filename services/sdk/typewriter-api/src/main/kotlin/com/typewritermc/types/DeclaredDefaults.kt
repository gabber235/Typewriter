package com.typewritermc.types

import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.UnsetFields
import com.typewritermc.authoring.complete
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner

/**
 * Unset fields read as their declared default: what the record's Kotlin constructor gives for the field when only the
 * stored fields are passed, so a default that reads another field reads the stored one. A field whose default cannot
 * run, such as one whose constructor still waits for an unfinished field, or fails, reads as unfilled.
 */
fun NativeBindingRegistry.declaredDefaults(catalog: CheckedCatalog): UnsetFields =
    UnsetFields { owner, stored, field ->
        val bindings = over(catalog)
        val inputs =
            owner.schema.fields.mapNotNull { declared ->
                val value = stored.field(declared.key) ?: return@mapNotNull null
                val type = (catalog.resolve(declared.type) as? Resolution.Ready)?.value ?: return@UnsetFields DataValue.UNFILLED
                val complete = type.complete(value) as? CompletenessResult.Complete ?: return@UnsetFields DataValue.UNFILLED
                FieldOwner(definition = declared.declarationOwner, name = declared.key) to complete.value
            }
        val declared = owner.schema.fields.single { it.key == field }
        when (val captured = bindings.sampleDefaults(owner, inputs.toMap())) {
            is CaptureResult.Captured -> {
                captured.values[FieldOwner(definition = declared.declarationOwner, name = field)]
                    ?: DataValue.UNFILLED
            }

            is CaptureResult.Unavailable -> {
                DataValue.UNFILLED
            }
        }
    }
