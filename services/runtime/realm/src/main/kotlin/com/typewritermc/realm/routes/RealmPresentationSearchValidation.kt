package com.typewritermc.realm.routes

import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeTemplate

/**
 * Collects request shape diagnostics before a search source can start work.
 *
 * This is transport boundary validation only. Generation, capability identity, and result type compatibility remain
 * owned by the search source because they require the current discovery snapshot.
 *
 * It checks required fields and known selector expression structure with a bounded node count. A null result means
 * these checks passed, not that catalog generation or capability types match.
 */
internal fun invalidRealmPresentationSearchRequest(request: RealmPresentationSearchRequest): RealmPresentationSearchUpdate? {
    val messages =
        buildList {
            if (request.subscriptionId.isBlank()) add("Realm presentation search subscription ID must not be blank")
            if (request.generation.value.isBlank()) add("Realm catalog generation must not be blank")
            if (request.capabilityId.value.isBlank()) add("Realm search capability ID must not be blank")
            if (request.payload == DataValue.UNKNOWN) add("Realm presentation search payload is missing")
            if (request.resultType == TypeTemplate.UNKNOWN) add("Realm presentation search result type is missing")
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
        diagnostics = messages.map(::realmDiagnostic),
    )
}

/**
 * Replaces a producer response whose subscription identity does not match the request being served.
 *
 * The route uses this as a containment boundary before publication, rather than forwarding an ambiguous update.
 */
internal fun invalidRealmPresentationSearchResponse(subscriptionId: String): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createSnapshot(
        subscriptionId = subscriptionId,
        status = RealmPresentationSearchStatus.ERROR,
        values = emptyList(),
        guidance = emptyList(),
        diagnostics =
            listOf(
                realmDiagnostic("Realm presentation search response used a different subscription ID"),
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
