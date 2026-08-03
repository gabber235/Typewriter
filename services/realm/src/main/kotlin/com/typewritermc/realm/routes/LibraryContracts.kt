package com.typewritermc.realm.routes

import build.skir.Serializer
import build.skir.service.Method
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
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
import skirout.library.v1.tag.MoveTag
import skirout.library.v1.tag.MoveTagResponse
import skirout.library.v1.tag.ResizeTag
import skirout.library.v1.tag.ResizeTagResponse
import skirout.library.v1.tag.UpdateTag
import skirout.library.v1.tag.UpdateTagResponse
import skirout.library.v1.tag.WatchTag
import skirout.library.v1.tag.WatchTagRequest
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTags
import skirout.library.v1.tag.WatchTagsResponse

data class RealmAddress(val realmId: String, val organizationId: String)

internal class LibraryContracts(private val address: RealmAddress) {
    val watchBooks = watch(
        WatchBooks,
        WatchBooksResponse.serializer,
        "book.watch",
        "book.watch",
        WatchBooksResponse.createInternalError(),
    )
    val watchBook = watch(
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
    val watchPage = watch(
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
    val changePagesChapters = unary(
        ChangePagesChapters,
        "pages.chapters",
        ChangePagesChaptersResponse.createInternalError(),
    )

    val watchTags = watch(
        WatchTags,
        WatchTagsResponse.serializer,
        "tag.watch",
        "tag.watch",
        WatchTagsResponse.createInternalError(),
    )
    val watchTag = watch(
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
    val moveTag = unary(MoveTag, "tag.move", MoveTagResponse.createInternalError())
    val resizeTag = unary(ResizeTag, "tag.resize", ResizeTagResponse.createInternalError())

    private fun <Request : Any, Response : Any> unary(
        method: Method<Request, Response>,
        suffix: String,
        internalFailureResponse: Response,
    ): UnaryContract<RealmAddress, Request, Response> = skirUnaryContract(
        method = method,
        name = OperationName.of(suffix),
        address = requestAddress(suffix).subscribedAt(address),
        responsePolicy = responsePolicy(internalFailureResponse),
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
    ): WatchContract<RealmAddress, Request, Response, Response> = skirWatchContract(
        method = method,
        updateSerializer = updateSerializer,
        name = OperationName.of(operation),
        requestAddress = requestAddress(suffix).subscribedAt(address),
        updateAddress = updateAddress(suffix),
        initialPolicy = responsePolicy(internalFailureResponse),
        updateClassifier = classifier,
        failureSlug = ErrorSlug.of(operation.replace('.', '-') + "-failed"),
        updateFilter = updateFilter,
    )
}

private fun requestAddress(suffix: String): AddressTemplate<RealmAddress> = realmAddress(
    "service.to.{realm}.organization.{organization}.realm.$suffix",
)

private fun updateAddress(suffix: String): AddressTemplate<RealmAddress> = realmAddress(
    "service.from.{realm}.organization.{organization}.realm.$suffix",
)

private fun realmAddress(pattern: String): AddressTemplate<RealmAddress> = addressTemplate(
    pattern,
    { address ->
        addressValuesOf(
            "realm" to address.realmId,
            "organization" to address.organizationId,
        )
    },
    { values -> RealmAddress(values.require("realm"), values.require("organization")) },
)

private fun <Response : Any> responsePolicy(internalFailureResponse: Response): ResponsePolicy<Response> =
    ResponsePolicy(internalFailureResponse, responseClassifier())

private fun <Response : Any> responseClassifier(): ResponseClassifier<Response> = ResponseClassifier { response ->
    val wrapper = requireNotNull(response::class.simpleName).removeSuffix("Wrapper")
    val words = wrapper.replace(Regex("([a-z0-9])([A-Z])"), "\$1-\$2").lowercase()
    val outcome = when (wrapper) {
        "InternalError" -> ResponseOutcome.INTERNAL_ERROR
        "Success", "List", "Initial", "Add", "Update", "Remove" -> ResponseOutcome.SUCCESS
        else -> ResponseOutcome.DOMAIN_ERROR
    }
    ResponseClassification(outcome, ResponseVariant.of(words))
}

private fun matchesBook(request: WatchBookRequest, response: WatchBookResponse): Boolean = when (response) {
    is WatchBookResponse.UpdateWrapper -> response.value.bookId == request.bookId
    is WatchBookResponse.RemoveWrapper -> response.value == request.bookId
    else -> true
}

private fun matchesPage(request: WatchPageRequest, response: WatchPageResponse): Boolean = when (response) {
    is WatchPageResponse.UpdateWrapper -> response.value.pageId == request.pageId
    is WatchPageResponse.RemoveWrapper -> response.value == request.pageId
    else -> true
}

private fun matchesTag(request: WatchTagRequest, response: WatchTagResponse): Boolean = when (response) {
    is WatchTagResponse.UpdateWrapper -> response.value.tagId == request.tagId
    is WatchTagResponse.RemoveWrapper -> response.value == request.tagId
    else -> true
}
