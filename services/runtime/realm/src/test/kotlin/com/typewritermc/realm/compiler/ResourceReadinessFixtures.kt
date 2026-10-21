package com.typewritermc.realm.compiler

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.complete
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.checking.CapturedCheckReport
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.fields
import com.typewritermc.types.named
import com.typewritermc.types.record
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.DataValue

internal fun testAssessment(
    view: AuthoringView,
    bindings: List<NativeBindingRequirement>,
): CapturedAssessment {
    val resources =
        view.resources.mapValues { (id, record) ->
            val actual = (record.configuration as? TypeSelection.Complete)?.use
            val checked = actual?.let { (view.catalog.checked.resolve(it.use) as? Resolution.Ready)?.value }
            val complete = checked?.complete(DataValue.named(actual, DataValue.record(record.fields)))
            when (complete) {
                is CompletenessResult.Complete -> {
                    ResourceReadiness.Ready(complete.value, bindings.single { it.actual == actual })
                }

                is CompletenessResult.Unfinished -> {
                    ResourceReadiness.Blocked(
                        complete.locations.map {
                            compilationDiagnostic("unfinished_value", "A required value is unfinished.", location = it.copy(resource = id))
                        },
                    )
                }

                else -> {
                    ResourceReadiness.Blocked(listOf(compilationDiagnostic("unresolved_type", "Unavailable type", source = id)))
                }
            }
        }
    return CapturedAssessment(
        resources,
        CapturedCheckReport(
            view.readContext,
            view.catalog.generation,
            emptySet(),
            emptyList(),
        ),
        resources.values.filterIsInstance<ResourceReadiness.Blocked>().flatMap {
            it.findings
        },
        emptyMap(),
    )
}
