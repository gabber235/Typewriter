package com.typewritermc.realm.routes

import build.skir.Serializer
import build.skir.service.Method
import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.loader.api.realmEventAddress
import com.typewritermc.loader.api.realmRequestAddress
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.EncodedPublication
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.FetchEditorCatalog
import skirout.editor.v1.catalog.WatchEditorCatalog
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvokeRealmCommand
import skirout.editor.v1.capability.InvokeRealmComputation
import skirout.editor.v1.element_catalog.ElementCatalogResult
import skirout.editor.v1.element_catalog.FetchElementCatalog
import skirout.editor.v1.search.CancelRealmPresentationSearch
import skirout.editor.v1.search.CancelRealmPresentationSearchResult
import skirout.library.v1.book.CreateBook
import skirout.library.v1.book.CreateBookResponse
import skirout.library.v1.book.UpdateBook
import skirout.library.v1.book.UpdateBookResponse
import skirout.library.v1.book.WatchBook
import skirout.library.v1.book.WatchBookRequest
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooks
import skirout.library.v1.book.WatchBooksResponse
import skirout.library.v1.page.ChangePagesChapters
import skirout.library.v1.page.ChangePagesChaptersResponse
import skirout.library.v1.page.CreatePage
import skirout.library.v1.page.CreatePageResponse
import skirout.library.v1.page.DeletePage
import skirout.library.v1.page.DeletePageResponse
import skirout.library.v1.page.SearchPages
import skirout.library.v1.page.SearchPagesResponse
import skirout.library.v1.page.UpdatePage
import skirout.library.v1.page.UpdatePageResponse
import skirout.library.v1.page.WatchPage
import skirout.library.v1.page.WatchPageRequest
import skirout.library.v1.page.WatchPageResponse
import skirout.library.v1.tag.CreateTag
import skirout.library.v1.tag.CreateTagResponse
import skirout.library.v1.tag.DeleteTag
import skirout.library.v1.tag.DeleteTagResponse
import skirout.library.v1.tag.UpdateTag
import skirout.library.v1.tag.UpdateTagResponse
import skirout.library.v1.tag.WatchTag
import skirout.library.v1.tag.WatchTagRequest
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTags
import skirout.library.v1.tag.WatchTagsResponse

typealias RealmAddress = RealmServiceAddress

internal class LibraryContracts(
    private val address: RealmAddress,
) {
    val fetchEditorCatalog =
        unary(
            FetchEditorCatalog,
            "editor.catalog.fetch",
            unavailableCatalogFetchResult("Realm editor catalog fetch failed"),
            catalogFetchResponseClassifier(),
        )
    val watchEditorCatalog =
        watch(
            WatchEditorCatalog,
            CatalogWatchUpdate.serializer,
            "editor.catalog.invalidate",
            "editor.catalog.invalidate",
            CatalogWatchUpdate.createInitial(value = "unavailable"),
            catalogWatchResponseClassifier(),
        )
    val fetchElementCatalog =
        unary(
            FetchElementCatalog,
            "editor.elements.fetch",
            ElementCatalogResult.UnavailableWrapper(listOf("Realm element catalog fetch failed")),
            elementCatalogResponseClassifier(),
        )
    val watchRealmPresentationSearch = realmPresentationSearchContract(address)
    val cancelRealmPresentationSearch =
        unary(
            CancelRealmPresentationSearch,
            "editor.presentation.search.cancel",
            CancelRealmPresentationSearchResult.UNAVAILABLE,
        )
    val invokeRealmComputation =
        unary(
            InvokeRealmComputation,
            "editor.capability.computation.invoke",
            ComputationResult.createUnavailable(
                invocationId = skirout.editor.v1.capability.InvocationId(value = ""),
                diagnostics = emptyList(),
            ),
        )
    val invokeRealmCommand =
        unary(
            InvokeRealmCommand,
            "editor.capability.command.invoke",
            CommandResult.createUnavailable(
                invocationId = skirout.editor.v1.capability.InvocationId(value = ""),
                diagnostics = emptyList(),
            ),
        )

    val watchBooks =
        watch(
            WatchBooks,
            WatchBooksResponse.serializer,
            "book.watch",
            "book.watch",
            WatchBooksResponse.createInternalError(),
        )
    val watchBook =
        watch(
            WatchBook,
            WatchBookResponse.serializer,
            "book.resource.watch",
            "book.resource.watch",
            WatchBookResponse.createInternalError(),
            updateFilter = ::matchesBook,
        )
    val createBook = unary(CreateBook, "book.create", CreateBookResponse.createInternalError())
    val updateBook = unary(UpdateBook, "book.update", UpdateBookResponse.createInternalError())

    val searchPages = unary(SearchPages, "page.search", SearchPagesResponse.createInternalError())
    val watchPage =
        watch(
            WatchPage,
            WatchPageResponse.serializer,
            "page.watch",
            "page.watch",
            WatchPageResponse.createInternalError(),
            updateFilter = ::matchesPage,
        )
    val createPage = unary(CreatePage, "page.create", CreatePageResponse.createInternalError())
    val updatePage = unary(UpdatePage, "page.update", UpdatePageResponse.createInternalError())
    val deletePage = unary(DeletePage, "page.delete", DeletePageResponse.createInternalError())
    val changePagesChapters =
        unary(
            ChangePagesChapters,
            "pages.chapters",
            ChangePagesChaptersResponse.createInternalError(),
        )

    val watchTags =
        watch(
            WatchTags,
            WatchTagsResponse.serializer,
            "tag.watch",
            "tag.watch",
            WatchTagsResponse.createInternalError(),
        )
    val watchTag =
        watch(
            WatchTag,
            WatchTagResponse.serializer,
            "tag.resource.watch",
            "tag.resource.watch",
            WatchTagResponse.createInternalError(),
            updateFilter = ::matchesTag,
        )
    val createTag = unary(CreateTag, "tag.create", CreateTagResponse.createInternalError())
    val updateTag = unary(UpdateTag, "tag.update", UpdateTagResponse.createInternalError())
    val deleteTag = unary(DeleteTag, "tag.delete", DeleteTagResponse.createInternalError())

    private fun <Request : Any, Response : Any> unary(
        method: Method<Request, Response>,
        suffix: String,
        internalFailureResponse: Response,
        classifier: ResponseClassifier<Response> = responseClassifier(),
    ): UnaryContract<RealmAddress, Request, Response> =
        skirUnaryContract(
            method = method,
            name = OperationName.of(suffix),
            address = requestAddress(suffix).subscribedAt(address),
            responsePolicy = ResponsePolicy(internalFailureResponse, classifier),
            failureSlug = ErrorSlug.of(suffix.replace('.', '-') + "-failed"),
        )

    private fun <Request : Any, Response : Any> watch(
        method: Method<Request, Response>,
        updateSerializer: Serializer<Response>,
        operation: String,
        suffix: String,
        internalFailureResponse: Response,
        classifier: ResponseClassifier<Response> = responseClassifier(),
        updateFilter: (Request, Response) -> Boolean = { _, _ -> true },
    ): WatchContract<RealmAddress, Request, Response, Response> =
        skirWatchContract(
            method = method,
            updateSerializer = updateSerializer,
            name = OperationName.of(operation),
            requestAddress = requestAddress(suffix).subscribedAt(address),
            updateAddress = updateAddress(suffix),
            initialPolicy = ResponsePolicy(internalFailureResponse, classifier),
            updateClassifier = classifier,
            failureSlug = ErrorSlug.of(operation.replace('.', '-') + "-failed"),
            updateFilter = updateFilter,
        )
}

private fun elementCatalogResponseClassifier(): ResponseClassifier<ElementCatalogResult> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is ElementCatalogResult.SuccessWrapper -> ResponseOutcome.SUCCESS
                is ElementCatalogResult.UnavailableWrapper -> ResponseOutcome.INTERNAL_ERROR
                else -> ResponseOutcome.DOMAIN_ERROR
            }
        ResponseClassification(
            outcome,
            ResponseVariant.of(
                response.kind.name
                    .lowercase()
                    .replace('_', '-'),
            ),
        )
    }

internal fun requestAddress(suffix: String): AddressTemplate<RealmAddress> = realmRequestAddress(suffix)

internal fun updateAddress(suffix: String): AddressTemplate<RealmAddress> = realmEventAddress(suffix)

private fun catalogFetchResponseClassifier(): ResponseClassifier<CatalogFetchResult> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is CatalogFetchResult.SuccessWrapper -> ResponseOutcome.SUCCESS
                is CatalogFetchResult.UnavailableWrapper -> ResponseOutcome.INTERNAL_ERROR
                else -> ResponseOutcome.DOMAIN_ERROR
            }
        ResponseClassification(
            outcome,
            ResponseVariant.of(
                requireNotNull(response::class.simpleName)
                    .removeSuffix("Wrapper")
                    .replace(Regex("([a-z0-9])([A-Z])"), "\$1-\$2")
                    .lowercase(),
            ),
        )
    }

private fun catalogWatchResponseClassifier(): ResponseClassifier<CatalogWatchUpdate> =
    ResponseClassifier { response ->
        val outcome =
            when (response) {
                is CatalogWatchUpdate.InitialWrapper -> {
                    if (response.value.value == "unavailable") {
                        ResponseOutcome.INTERNAL_ERROR
                    } else {
                        ResponseOutcome.SUCCESS
                    }
                }

                is CatalogWatchUpdate.InvalidatedWrapper -> {
                    ResponseOutcome.SUCCESS
                }

                else -> {
                    ResponseOutcome.DOMAIN_ERROR
                }
            }
        val variant =
            requireNotNull(response::class.simpleName)
                .removeSuffix("Wrapper")
                .replace(Regex("([a-z0-9])([A-Z])"), "\$1-\$2")
                .lowercase()
        ResponseClassification(outcome, ResponseVariant.of(variant))
    }

private fun <Response : Any> responseClassifier(): ResponseClassifier<Response> =
    ResponseClassifier { response ->
        val wrapper = requireNotNull(response::class.simpleName).removeSuffix("Wrapper")
        val variant =
            wrapper
                .replace(Regex("([a-z0-9])([A-Z])"), "\$1-\$2")
                .replace('_', '-')
                .lowercase()
        val outcome =
            when (variant) {
                "internal-error", "unavailable" -> ResponseOutcome.INTERNAL_ERROR
                "success", "list", "initial", "add", "update", "remove", "canceled" -> ResponseOutcome.SUCCESS
                else -> ResponseOutcome.DOMAIN_ERROR
            }
        ResponseClassification(outcome, ResponseVariant.of(variant))
    }

internal fun <Request : Any, Initial : Any, Update : Any> WatchContract<RealmAddress, Request, Initial, Update>.encodeUpdate(
    address: RealmAddress,
    update: Update,
): EncodedPublication = EncodedPublication(updateAddress.render(address), updateCodec.encode(update))

private fun matchesBook(
    request: WatchBookRequest,
    response: WatchBookResponse,
): Boolean =
    when (response) {
        is WatchBookResponse.UpdateWrapper -> response.value.bookId == request.bookId
        is WatchBookResponse.RemoveWrapper -> response.value == request.bookId
        else -> true
    }

private fun matchesPage(
    request: WatchPageRequest,
    response: WatchPageResponse,
): Boolean =
    when (response) {
        is WatchPageResponse.UpdateWrapper -> response.value.pageId == request.pageId
        is WatchPageResponse.RemoveWrapper -> response.value == request.pageId
        else -> true
    }

private fun matchesTag(
    request: WatchTagRequest,
    response: WatchTagResponse,
): Boolean =
    when (response) {
        is WatchTagResponse.UpdateWrapper -> response.value.tagId == request.tagId
        is WatchTagResponse.RemoveWrapper -> response.value == request.tagId
        else -> true
    }
