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
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvokeRealmCommand
import skirout.editor.v1.capability.InvokeRealmComputation
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.FetchEditorCatalog
import skirout.editor.v1.catalog.WatchEditorCatalog
import skirout.editor.v1.search.CancelRealmPresentationSearch
import skirout.editor.v1.search.CancelRealmPresentationSearchResult
import skirout.library.v1.book.WatchBook
import skirout.library.v1.book.WatchBookRequest
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooks
import skirout.library.v1.book.WatchBooksResponse
import skirout.library.v1.page.SearchPages
import skirout.library.v1.page.SearchPagesResponse
import skirout.library.v1.page.WatchPage
import skirout.library.v1.page.WatchPageRequest
import skirout.library.v1.page.WatchPageResponse
import skirout.library.v1.tag.WatchTag
import skirout.library.v1.tag.WatchTagRequest
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTags
import skirout.library.v1.tag.WatchTagsResponse
import skirout.library.v2.authoring.CreateBooks
import skirout.library.v2.authoring.CreateBooksResponse
import skirout.library.v2.authoring.CreateElements
import skirout.library.v2.authoring.CreateElementsResponse
import skirout.library.v2.authoring.CreatePages
import skirout.library.v2.authoring.CreatePagesResponse
import skirout.library.v2.authoring.CreateTags
import skirout.library.v2.authoring.CreateTagsResponse
import skirout.library.v2.authoring.DeleteBooks
import skirout.library.v2.authoring.DeleteBooksResponse
import skirout.library.v2.authoring.DeleteElements
import skirout.library.v2.authoring.DeleteElementsResponse
import skirout.library.v2.authoring.DeletePages
import skirout.library.v2.authoring.DeletePagesResponse
import skirout.library.v2.authoring.DeleteTags
import skirout.library.v2.authoring.DeleteTagsResponse
import skirout.library.v2.authoring.DuplicateElements
import skirout.library.v2.authoring.DuplicateElementsResponse
import skirout.library.v2.authoring.GetPageDocument
import skirout.library.v2.authoring.GetPageDocumentResponse
import skirout.library.v2.authoring.MoveElementsToPages
import skirout.library.v2.authoring.MoveElementsToPagesResponse
import skirout.library.v2.authoring.MoveGraphElements
import skirout.library.v2.authoring.MoveGraphElementsResponse
import skirout.library.v2.authoring.MovePages
import skirout.library.v2.authoring.MovePagesResponse
import skirout.library.v2.authoring.ResizeGraphElements
import skirout.library.v2.authoring.ResizeGraphElementsResponse
import skirout.library.v2.authoring.UpdateBooks
import skirout.library.v2.authoring.UpdateBooksResponse
import skirout.library.v2.authoring.UpdateCueTimings
import skirout.library.v2.authoring.UpdateCueTimingsResponse
import skirout.library.v2.authoring.UpdateElementValues
import skirout.library.v2.authoring.UpdateElementValuesResponse
import skirout.library.v2.authoring.UpdatePages
import skirout.library.v2.authoring.UpdatePagesResponse
import skirout.library.v2.authoring.UpdateTags
import skirout.library.v2.authoring.UpdateTagsResponse
import skirout.library.v2.authoring.WatchCompiledContent
import skirout.library.v2.authoring.WatchCompiledContentResponse
import skirout.library.v2.authoring.WatchLibraryInvalidations
import skirout.library.v2.authoring.WatchLibraryInvalidationsResponse
import skirout.library.v2.authoring.WatchPageDocuments
import skirout.library.v2.authoring.WatchPageDocumentsRequest
import skirout.library.v2.authoring.WatchPageDocumentsResponse

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
                invocationId =
                    skirout.editor.v1.capability
                        .InvocationId(value = ""),
                diagnostics = emptyList(),
            ),
        )
    val invokeRealmCommand =
        unary(
            InvokeRealmCommand,
            "editor.capability.command.invoke",
            CommandResult.createUnavailable(
                invocationId =
                    skirout.editor.v1.capability
                        .InvocationId(value = ""),
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
    val getPageDocument =
        unary(
            GetPageDocument,
            "page.document.get.v2",
            GetPageDocumentResponse.createInternalError(message = "Page document request failed"),
        )
    val watchPageDocuments =
        watch(
            WatchPageDocuments,
            WatchPageDocumentsResponse.serializer,
            "page.document.watch.v2",
            "page.document.watch.v2",
            WatchPageDocumentsResponse.createInternalError(message = "Page document watch failed"),
            updateFilter = ::matchesPageDocuments,
        )
    val watchLibraryInvalidations =
        watch(
            WatchLibraryInvalidations,
            WatchLibraryInvalidationsResponse.serializer,
            "library.invalidate.watch.v2",
            "library.invalidate.watch.v2",
            WatchLibraryInvalidationsResponse.createInternalError(message = "Library invalidation watch failed"),
        )
    val watchCompiledContent =
        watch(
            WatchCompiledContent,
            WatchCompiledContentResponse.serializer,
            "compiled.content.watch.v2",
            "compiled.content.watch.v2",
            WatchCompiledContentResponse.createInternalError(message = "Compiled content watch failed"),
        )
    val createElements =
        unary(CreateElements, "element.create.v2", CreateElementsResponse.createInternalError(message = "Element create failed"))
    val updateElementValues =
        unary(
            UpdateElementValues,
            "element.value.update.v2",
            UpdateElementValuesResponse.createInternalError(message = "Element update failed"),
        )
    val moveElementsToPages =
        unary(
            MoveElementsToPages,
            "element.page.move.v2",
            MoveElementsToPagesResponse.createInternalError(message = "Element page move failed"),
        )
    val moveGraphElements =
        unary(
            MoveGraphElements,
            "element.graph.move.v2",
            MoveGraphElementsResponse.createInternalError(message = "Element graph move failed"),
        )
    val resizeGraphElements =
        unary(
            ResizeGraphElements,
            "element.graph.resize.v2",
            ResizeGraphElementsResponse.createInternalError(message = "Element graph resize failed"),
        )
    val updateCueTimings =
        unary(
            UpdateCueTimings,
            "element.cue.timing.update.v2",
            UpdateCueTimingsResponse.createInternalError(message = "Cue timing update failed"),
        )
    val deleteElements =
        unary(DeleteElements, "element.delete.v2", DeleteElementsResponse.createInternalError(message = "Element delete failed"))
    val duplicateElements =
        unary(
            DuplicateElements,
            "element.duplicate.v2",
            DuplicateElementsResponse.createInternalError(message = "Element duplication failed"),
        )
    val createPagesV2 = unary(CreatePages, "page.create.v2", CreatePagesResponse.createInternalError(message = "Page create failed"))
    val updatePagesV2 = unary(UpdatePages, "page.update.v2", UpdatePagesResponse.createInternalError(message = "Page update failed"))
    val movePagesV2 = unary(MovePages, "page.move.v2", MovePagesResponse.createInternalError(message = "Page move failed"))
    val deletePagesV2 = unary(DeletePages, "page.delete.v2", DeletePagesResponse.createInternalError(message = "Page delete failed"))
    val createBooksV2 = unary(CreateBooks, "book.create.v2", CreateBooksResponse.createInternalError(message = "Book create failed"))
    val updateBooksV2 = unary(UpdateBooks, "book.update.v2", UpdateBooksResponse.createInternalError(message = "Book update failed"))
    val deleteBooksV2 = unary(DeleteBooks, "book.delete.v2", DeleteBooksResponse.createInternalError(message = "Book delete failed"))
    val createTagsV2 = unary(CreateTags, "tag.create.v2", CreateTagsResponse.createInternalError(message = "Tag create failed"))
    val updateTagsV2 = unary(UpdateTags, "tag.update.v2", UpdateTagsResponse.createInternalError(message = "Tag update failed"))
    val deleteTagsV2 = unary(DeleteTags, "tag.delete.v2", DeleteTagsResponse.createInternalError(message = "Tag delete failed"))

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
                "success", "list", "initial", "activated", "add", "update", "remove", "canceled" -> ResponseOutcome.SUCCESS
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

private fun matchesPageDocuments(
    request: WatchPageDocumentsRequest,
    response: WatchPageDocumentsResponse,
): Boolean =
    when (response) {
        is WatchPageDocumentsResponse.InvalidatedWrapper -> {
            request.pageIds.isEmpty() || response.value.pageIds.any { it in request.pageIds }
        }

        else -> {
            true
        }
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
