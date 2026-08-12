package com.typewritermc.realm.routes

import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.TypeDiagnostic

interface RealmEditorCatalogSource {
    suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult

    suspend fun watch(
        request: WatchEditorCatalogRequest,
        invalidations: RealmEditorCatalogInvalidationPublisher,
    ): CatalogWatchUpdate
}

fun interface RealmEditorCatalogInvalidationPublisher {
    suspend fun publish(update: CatalogWatchUpdate)
}

class UnavailableRealmEditorCatalogSource : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult =
        CatalogFetchResult.UnavailableWrapper(listOf(unavailableDiagnostic()))

    override suspend fun watch(
        request: WatchEditorCatalogRequest,
        invalidations: RealmEditorCatalogInvalidationPublisher,
    ): CatalogWatchUpdate = CatalogWatchUpdate.createInitial(value = "unavailable")
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
