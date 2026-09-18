package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.search.AuthoringReferenceResolutionRequest
import com.typewritermc.realm.repository.search.AuthoringReferenceScope
import com.typewritermc.realm.repository.search.AuthoringReferenceSummary
import com.typewritermc.realm.repository.search.AuthoringSearchFilter
import com.typewritermc.realm.repository.search.AuthoringSearchRepository
import com.typewritermc.realm.repository.search.AuthoringSearchRequest
import com.typewritermc.realm.repository.search.AuthoringSelectorKind
import com.typewritermc.realm.repository.search.AuthoringSelectorSuggestionRequest
import com.typewritermc.realm.repository.search.SearchFilterExpression
import com.typewritermc.realm.repository.search.conjunction
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.library.v1.authoring.AuthoringDiagnostic
import skirout.library.v1.authoring.AuthoringInvalid
import skirout.library.v1.authoring.AuthoringSelectorSuggestions
import skirout.library.v1.authoring.ReferenceResourceSummary
import skirout.library.v1.authoring.ResolveAuthoringResourcesResponse
import skirout.library.v1.authoring.SearchAuthoringContentRequest
import skirout.library.v1.authoring.SearchAuthoringContentResponse
import skirout.library.v1.authoring.SuggestAuthoringSelectorValuesRequest
import skirout.library.v1.authoring.SuggestAuthoringSelectorValuesResponse

/** Exposes Realm owned authoring search through the shared query contract. */
internal class AuthoringSearchRoutes(
    private val repository: AuthoringSearchRepository,
    private val contracts: LibraryContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.searchAuthoringContent) { call ->
                try {
                    repository
                        .search(call.request.toAuthoringSearchRequest())
                        .toWireResponse()
                } catch (invalid: IllegalArgumentException) {
                    invalidSearchResponse(invalid.message ?: "Invalid authoring search request.")
                }
            }
            unary(contracts.suggestAuthoringSelectorValues) { call ->
                try {
                    val suggestions = repository.suggest(call.request.toSuggestionRequest())
                    SuggestAuthoringSelectorValuesResponse.SuccessWrapper(
                        AuthoringSelectorSuggestions(
                            values = suggestions.values,
                            exhaustive = suggestions.exhaustive,
                        ),
                    )
                } catch (invalid: IllegalArgumentException) {
                    SuggestAuthoringSelectorValuesResponse.InvalidWrapper(
                        AuthoringInvalid(
                            diagnostics =
                                listOf(
                                    AuthoringDiagnostic(
                                        code = "invalid-selector-suggestion-request",
                                        message = invalid.message ?: "Invalid selector suggestion request.",
                                        resource = null,
                                        path = null,
                                    ),
                                ),
                        ),
                    )
                }
            }
            unary(contracts.resolveAuthoringResources) { call ->
                try {
                    val request = call.request
                    ResolveAuthoringResourcesResponse.createSuccess(
                        resources =
                            repository
                                .resolve(
                                    AuthoringReferenceResolutionRequest(
                                        request.ids.map { it.toResourceId() },
                                        SkirTypeCodec.decode(request.referenceTarget).getOrThrow(),
                                    ),
                                ).map(AuthoringReferenceSummary::toWire),
                    )
                } catch (invalid: IllegalArgumentException) {
                    ResolveAuthoringResourcesResponse.createInvalid(
                        diagnostics =
                            listOf(
                                AuthoringDiagnostic(
                                    code = "invalid-reference-resolution-request",
                                    message = invalid.message ?: "Invalid reference resolution request.",
                                    resource = null,
                                    path = null,
                                ),
                            ),
                    )
                }
            }
        }
}

internal fun SearchAuthoringContentRequest.toAuthoringSearchRequest(): AuthoringSearchRequest =
    AuthoringSearchRequest(
        query = query.normalizedQuery,
        terms = query.terms,
        filter =
            query.selectorExpression?.toAuthoringFilterExpression()
                ?: query.selectors.mapNotNull(RealmSearchSelector::toAuthoringFilter).conjunction(),
        contextPage = contextPage?.toPageId(),
        referenceScope =
            referenceScope?.let { scope ->
                require(contextPage == null) { "Reference search cannot use context_page." }
                require(query.selectors.isEmpty() && query.selectorExpression == null) {
                    "Reference search cannot use selectors."
                }
                AuthoringReferenceScope(
                    origins = scope.origins.map { it.toResourceId() },
                    target = SkirTypeCodec.decode(scope.target).getOrThrow(),
                )
            },
    )

private fun AuthoringReferenceSummary.toWire(): ReferenceResourceSummary =
    ReferenceResourceSummary(
        id = id.toSkirRecordId(),
        title = title,
        subtitle = subtitle,
        compatibleTypes = compatibleTypes.map { SkirTypeCodec.encode(it).getOrThrow() },
        exists = exists,
    )

private fun SuggestAuthoringSelectorValuesRequest.toSuggestionRequest() =
    AuthoringSelectorSuggestionRequest(
        kind = selector.toDomain(),
        partial = partial,
        filter = scope?.toAuthoringFilterExpression(),
        contextPage = contextPage?.toPageId(),
    )

private fun skirout.library.v1.authoring.AuthoringSelectorKind.toDomain(): AuthoringSelectorKind =
    when (this) {
        skirout.library.v1.authoring.AuthoringSelectorKind.BOOK -> AuthoringSelectorKind.BOOK
        skirout.library.v1.authoring.AuthoringSelectorKind.PAGE -> AuthoringSelectorKind.PAGE
        skirout.library.v1.authoring.AuthoringSelectorKind.TAG -> AuthoringSelectorKind.TAG
        skirout.library.v1.authoring.AuthoringSelectorKind.ELEMENT_TYPE -> AuthoringSelectorKind.ELEMENT_TYPE
        else -> throw IllegalArgumentException("Unknown authoring selector kind.")
    }

private fun RealmSearchSelectorExpression.toAuthoringFilterExpression(): SearchFilterExpression<AuthoringSearchFilter>? =
    when (this) {
        is RealmSearchSelectorExpression.SelectorWrapper -> {
            value.toAuthoringFilter()?.let(SearchFilterExpression<AuthoringSearchFilter>::Value)
        }

        is RealmSearchSelectorExpression.BinaryWrapper -> {
            when (value.operator_) {
                skirout.editor.v1.search.RealmSearchSelectorOperator.AND -> {
                    combine(
                        value.left.toAuthoringFilterExpression(),
                        value.right.toAuthoringFilterExpression(),
                        SearchFilterExpression<AuthoringSearchFilter>::And,
                    )
                }

                skirout.editor.v1.search.RealmSearchSelectorOperator.OR -> {
                    combine(
                        value.left.toAuthoringFilterExpression(),
                        value.right.toAuthoringFilterExpression(),
                        SearchFilterExpression<AuthoringSearchFilter>::Or,
                    )
                }

                else -> {
                    throw IllegalArgumentException("Unknown Realm search selector operator.")
                }
            }
        }

        is RealmSearchSelectorExpression.NotWrapper -> {
            value.expression.toAuthoringFilterExpression()?.let(SearchFilterExpression<AuthoringSearchFilter>::Not)
        }

        else -> {
            throw IllegalArgumentException("Unknown Realm search selector expression.")
        }
    }

private fun RealmSearchSelector.toAuthoringFilter(): AuthoringSearchFilter? {
    val kind =
        when (selectorId) {
            "book" -> AuthoringSelectorKind.BOOK
            "page" -> AuthoringSelectorKind.PAGE
            "tag" -> AuthoringSelectorKind.TAG
            "type" -> AuthoringSelectorKind.ELEMENT_TYPE
            else -> return null
        }
    return AuthoringSearchFilter(kind, requireNotNull(value) { "Selector $selectorId requires a value." })
}

private fun <T> combine(
    left: T?,
    right: T?,
    operation: (T, T) -> T,
): T? =
    when {
        left == null -> right
        right == null -> left
        else -> operation(left, right)
    }

private fun invalidSearchResponse(message: String): SearchAuthoringContentResponse =
    SearchAuthoringContentResponse.InvalidWrapper(
        AuthoringInvalid(
            diagnostics =
                listOf(
                    AuthoringDiagnostic(
                        code = "invalid-search-request",
                        message = message,
                        resource = null,
                        path = null,
                    ),
                ),
        ),
    )
