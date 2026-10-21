package com.typewritermc.realm.authoring

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.PreparationOperation
import com.typewritermc.authoring.PreparationStep
import skirout.editor.v1.type_catalog.CatalogGeneration

internal fun interface PreparationEvaluator {
    suspend fun evaluate(
        operation: PreparationOperation,
        catalog: AuthoringCatalogLease,
    ): PreparationStep
}

internal class PreparationCatalogChanged(
    val actual: CatalogGeneration,
) : IllegalStateException("The active catalog changed to ${actual.value}.")

/** Evaluates value preparation using retained catalog services. Callers retain the prepared value. */
internal class PreparationCoordinator(
    private val catalog: () -> AuthoringCatalogLease,
    private val evaluator: PreparationEvaluator,
) : InitializationRuntime {
    override suspend fun step(operation: PreparationOperation): PreparationStep {
        val active = catalog()
        return try {
            val generation =
                when (operation) {
                    is PreparationOperation.Start -> operation.request.catalog
                    is PreparationOperation.Resume -> operation.draft.catalog
                }
            if (generation != active.generation) throw PreparationCatalogChanged(active.generation)
            evaluator.evaluate(operation, active)
        } finally {
            active.close()
        }
    }
}
