package com.typewritermc.realm.routes

import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.TypeDiagnostic
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchUpdate

interface RealmPresentationSearchSource {
    suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate
}

fun interface RealmPresentationSearchUpdatePublisher {
    suspend fun publish(update: RealmPresentationSearchUpdate)
}

class UnavailableRealmPresentationSearchSource : RealmPresentationSearchSource {
    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate = unavailableRealmPresentationSearchUpdate(request.subscriptionId)
}

internal fun unavailableRealmPresentationSearchUpdate(
    subscriptionId: String,
    message: String = "Realm presentation search source is unavailable",
): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createUnavailable(
        subscriptionId = subscriptionId,
        diagnostics = listOf(realmPresentationSearchDiagnostic(DiagnosticCode.INVALID_PRESENTATION, message)),
    )

internal fun realmPresentationSearchDiagnostic(
    code: DiagnosticCode,
    message: String,
): TypeDiagnostic =
    TypeDiagnostic(
        code = code,
        severity = DiagnosticSeverity.ERROR,
        message = message,
        path = null,
        relatedType = null,
        details = emptyList(),
    )
