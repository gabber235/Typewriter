package com.typewritermc.realm.operation

import com.typewritermc.authoring.of
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.types.fields
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection

/**
 * The preparation coordinator a Realm runs, preparing with [evaluator] against the catalog this Realm runs at the time
 * of each call.
 */
internal fun RealmFixture.preparations(evaluator: PreparationEvaluator) =
    PreparationCoordinator(catalog = { views.read { it.catalog.retain() } }, evaluator = evaluator)

/** A request to prepare a creation value on [catalog], whose supplied value carries [supplied] as its seed. */
internal fun request(
    catalog: CatalogGeneration,
    supplied: String = "seed",
): ValuePreparationRequest =
    ValuePreparationRequest(
        catalog = catalog,
        target =
            PreparationTarget.RecordWrapper(
                TypeSelection.createPending(definition = CREATION_TYPE, arguments = listOf(ArgumentSelection.UNFILLED)),
            ),
        suppliedValue = DataValue.record(mapOf("seed" to DataValue.StringValueWrapper(supplied))),
    )

internal fun prepared(value: String) =
    PreparedValue(
        content =
            PreparedContent.RecordWrapper(
                AuthoringRecord.of(
                    configuration = TypeSelection.createPending(definition = CREATION_TYPE, arguments = listOf(ArgumentSelection.UNFILLED)),
                    fields = mapOf("value" to DataValue.StringValueWrapper(value)),
                ),
            ),
        findings = emptyList(),
    )

internal val CREATION_TYPE = TypeDefinitionId.qualified("creation", "value")
