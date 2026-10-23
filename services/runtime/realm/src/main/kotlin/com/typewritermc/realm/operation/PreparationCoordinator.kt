package com.typewritermc.realm.operation

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.catalog.PreparationOperation
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.type_catalog.CatalogGeneration

internal fun interface PreparationEvaluator {
    suspend fun evaluate(
        operation: PreparationOperation,
        catalog: AuthoringCatalogLease,
    ): PrepareValueResult
}

internal class PreparationCatalogChanged(
    val actual: CatalogGeneration,
) : IllegalStateException("The active catalog changed to ${actual.value}.")

/** Evaluates value preparation using retained catalog services. Callers retain the prepared value. */
internal class PreparationCoordinator(
    private val catalog: () -> AuthoringCatalogLease,
    private val evaluator: PreparationEvaluator,
) : InitializationRuntime {
    override suspend fun step(operation: PreparationOperation): PrepareValueResult {
        val active = catalog()
        return try {
            val generation =
                when (operation) {
                    is PreparationOperation.StartWrapper -> operation.value.catalog
                    is PreparationOperation.ResumeWrapper -> operation.value.draft.catalog
                    else -> unknownVariant(operation)
                }
            if (generation != active.generation) throw PreparationCatalogChanged(active.generation)
            evaluator.evaluate(operation, active)
        } finally {
            active.close()
        }
    }
}
