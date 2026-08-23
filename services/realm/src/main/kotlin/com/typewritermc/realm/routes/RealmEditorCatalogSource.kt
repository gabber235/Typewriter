package com.typewritermc.realm.routes

import com.typewritermc.discovery.DeploymentDiscoverySnapshot
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogGeneration
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.SubtypeResult
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.TypeDiagnostic

interface RealmEditorCatalogSource {
    suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult

    suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate
}

fun interface RealmDiscoverySnapshotProvider {
    suspend fun snapshot(): DeploymentDiscoverySnapshot?
}

class SnapshotRealmEditorCatalogSource(
    private val provider: RealmDiscoverySnapshotProvider,
) : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult {
        val snapshot = provider.snapshot() ?: return unavailableCatalogFetchResult("Realm discovery snapshot is unavailable")
        val generation = snapshot.generation.value
        if (request.expectedGeneration?.value != null && request.expectedGeneration?.value != generation) {
            return CatalogFetchResult.createGenerationMismatch(actualGeneration = CatalogGeneration(value = generation))
        }
        request.requestedTypes.forEach { SkirTypeCodec.decode(it).getOrThrow() }
        val encoded = SkirTypeCodec.encode(snapshot.types).getOrThrow()
        val subtypeResults =
            request.subtypeQueries.map { query ->
                val target = SkirTypeCodec.decode(query.target).getOrThrow()
                SubtypeResult(
                    queryId = query.queryId,
                    matchingTypes =
                        snapshot.types
                            .subtypesOf(target)
                            .map { SkirTypeCodec.encode(it.id).getOrThrow() },
                )
            }
        return CatalogFetchResult.createSuccess(
            generation = CatalogGeneration(value = generation),
            typeDefinitions = encoded.definitions,
            presentationDefinitions = emptyList(),
            conversions = emptyList(),
            realmActionDefinitions = emptyList(),
            subtypeResults = subtypeResults,
            diagnostics = emptyList(),
        )
    }

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(value = provider.snapshot()?.generation?.value ?: "unavailable")
}

class UnavailableRealmEditorCatalogSource : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult =
        CatalogFetchResult.UnavailableWrapper(listOf(unavailableDiagnostic()))

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(value = "unavailable")
}

internal fun unavailableCatalogFetchResult(message: String): CatalogFetchResult =
    CatalogFetchResult.UnavailableWrapper(listOf(unavailableDiagnostic(message)))

private fun unavailableDiagnostic(message: String = "Realm editor catalog source is unavailable"): TypeDiagnostic =
    TypeDiagnostic(
        code = DiagnosticCode.INVALID_PRESENTATION,
        severity = DiagnosticSeverity.ERROR,
        message = message,
        path = null,
        relatedType = null,
        details = emptyList(),
    )
