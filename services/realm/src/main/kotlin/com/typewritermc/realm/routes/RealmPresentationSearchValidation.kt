package com.typewritermc.realm.routes

import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.type_catalog.TypeExpression
import skirout.editor.v1.type_catalog.TypedValue

internal fun invalidRealmPresentationSearchRequest(request: RealmPresentationSearchRequest): RealmPresentationSearchUpdate? {
    val messages =
        buildList {
            if (request.subscriptionId.isBlank()) add("Realm presentation search subscription ID must not be blank")
            if (request.generation.value.isBlank()) add("Realm catalog generation must not be blank")
            if (request.capabilityId.value.isBlank()) add("Realm search capability ID must not be blank")
            if (request.payload == TypedValue.UNKNOWN) add("Realm presentation search payload is missing")
            if (request.resultType == TypeExpression.UNKNOWN) add("Realm presentation search result type is missing")
            request.query.selectors.forEach { selector ->
                if (selector.selectorId.isBlank()) add("Realm search selector ID must not be blank")
                if (selector.key.isBlank()) add("Realm search selector key must not be blank")
            }
            request.query.selectorExpression
                ?.validationMessage()
                ?.let(::add)
        }
    if (messages.isEmpty()) return null

    return RealmPresentationSearchUpdate.createSnapshot(
        subscriptionId = request.subscriptionId,
        status = RealmPresentationSearchStatus.ERROR,
        values = emptyList(),
        guidance = emptyList(),
        diagnostics = messages.map { message -> realmPresentationSearchDiagnostic(DiagnosticCode.INVALID_VALUE, message) },
    )
}

internal fun invalidRealmPresentationSearchResponse(subscriptionId: String): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createSnapshot(
        subscriptionId = subscriptionId,
        status = RealmPresentationSearchStatus.ERROR,
        values = emptyList(),
        guidance = emptyList(),
        diagnostics =
            listOf(
                realmPresentationSearchDiagnostic(
                    DiagnosticCode.INVALID_VALUE,
                    "Realm presentation search response used a different subscription ID",
                ),
            ),
    )

private fun RealmSearchSelectorExpression.validationMessage(): String? {
    val pending = ArrayDeque<RealmSearchSelectorExpression>()
    pending.add(this)
    var count = 0

    while (pending.isNotEmpty()) {
        if (++count > MAXIMUM_SELECTOR_EXPRESSION_NODES) {
            return "Realm search selector expression is too complex"
        }
        when (val expression = pending.removeLast()) {
            is RealmSearchSelectorExpression.SelectorWrapper -> {
                if (expression.value.selectorId.isBlank()) return "Realm search selector ID must not be blank"
                if (expression.value.key.isBlank()) return "Realm search selector key must not be blank"
            }

            is RealmSearchSelectorExpression.BinaryWrapper -> {
                pending.add(expression.value.left)
                pending.add(expression.value.right)
            }

            is RealmSearchSelectorExpression.NotWrapper -> {
                pending.add(expression.value.expression)
            }

            else -> {
                return "Realm search selector expression contains an unknown variant"
            }
        }
    }
    return null
}

private const val MAXIMUM_SELECTOR_EXPRESSION_NODES = 256
