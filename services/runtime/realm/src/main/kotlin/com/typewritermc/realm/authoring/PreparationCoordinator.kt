package com.typewritermc.realm.authoring

import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.checking.CatalogGeneration

internal fun interface PreparationEvaluator {
    suspend fun evaluate(
        request: InitializationRequest,
        catalog: AuthoringCatalogLease,
    ): PreparedValue
}

internal class PreparationCatalogChanged(
    val actual: CatalogGeneration,
) : IllegalStateException("The active catalog changed to ${actual.value}.")

/** Evaluates value preparation using retained catalog services. Callers retain the prepared value. */
internal class PreparationCoordinator(
    private val catalog: () -> AuthoringCatalogLease,
    private val evaluator: PreparationEvaluator,
) : InitializationRuntime {
    override suspend fun prepare(request: InitializationRequest): PreparedValue {
        val active = catalog()
        return try {
            if (request.catalog != active.generation) throw PreparationCatalogChanged(active.generation)
            evaluator.evaluate(request, active)
        } finally {
            active.close()
        }
    }
}
