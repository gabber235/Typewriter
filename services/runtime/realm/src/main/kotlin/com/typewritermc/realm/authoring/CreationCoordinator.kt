package com.typewritermc.realm.authoring

import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.PreparedCreation
import com.typewritermc.checking.CatalogGeneration

internal fun interface CreationEvaluator {
    suspend fun evaluate(
        request: InitializationRequest,
        catalog: AuthoringCatalogLease,
    ): PreparedCreation
}

internal class CreationCatalogChanged(
    val actual: CatalogGeneration,
) : IllegalStateException("The active catalog changed to ${actual.value}.")

/** Evaluates creation defaults using retained catalog services. Callers retain the returned draft. */
internal class CreationCoordinator(
    private val catalog: () -> AuthoringCatalogLease,
    private val evaluator: CreationEvaluator,
) : InitializationRuntime {
    override suspend fun prepare(request: InitializationRequest): PreparedCreation {
        val active = catalog()
        return try {
            if (request.catalog != active.generation) throw CreationCatalogChanged(active.generation)
            evaluator.evaluate(request, active)
        } finally {
            active.close()
        }
    }
}
