package com.typewritermc.protocol.transport.generated

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.skir.asPayloadCodec
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import skirout.editor.v1.authoring.CommitPreparedEdit
import skirout.editor.v1.authoring.PrepareTypeArgumentChange
import skirout.editor.v1.authoring.PreviewTypeArgumentChange
import skirout.editor.v1.authoring.QueryAuthoringState
import skirout.editor.v1.authoring.SearchAuthoring
import skirout.editor.v1.capability.InvokeRealmCommand
import skirout.editor.v1.capability.InvokeRealmComputation
import skirout.editor.v1.catalog.FetchEditorCatalog
import skirout.editor.v1.catalog.PrepareValue
import skirout.editor.v1.catalog.WatchEditorCatalog
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryPublishedContent
import skirout.editor.v1.publication.PublishAuthoring
import skirout.editor.v1.publication.WatchPublication
import skirout.editor.v1.search.CancelRealmPresentationSearch
import skirout.editor.v1.search.WatchRealmPresentationSearch
import skirout.service.v1.artifact.BeginArtifactBlobWrite
import skirout.service.v1.artifact.CompleteArtifactBlobWrite
import skirout.service.v1.artifact.FetchArtifactBlobMetadata
import skirout.service.v1.artifact.FetchSharedArtifactCatalog
import skirout.service.v1.artifact.PublishSharedArtifact
import skirout.service.v1.artifact.ReadArtifactBlob
import skirout.service.v1.artifact.WriteArtifactBlobChunk

data class RealmRouteScope(val organizationId: String, val realmId: String)
private fun String.realmTemplate() = addressTemplate(
    render = { it: RealmRouteScope -> addressValuesOf("organization" to it.organizationId, "realm" to it.realmId) },
    parse = { RealmRouteScope(it.require("organization"), it.require("realm")) },
)

private val editorCatalogFetchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.catalog.fetch".realmTemplate()
private val editorCatalogFetchUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.catalog.fetch".realmTemplate()
fun RealmRouteScope.editorCatalogFetch(policy: ResponsePolicy<skirout.editor.v1.catalog.CatalogFetchResult>, updates: ResponseClassifier<skirout.editor.v1.catalog.CatalogFetchResult>) = skirWatchContract(
    method = FetchEditorCatalog, updateSerializer = skirout.editor.v1.catalog.CatalogFetchResult.serializer,
    name = OperationName.of("editor.catalog.fetch"), requestAddress = editorCatalogFetchRequestAddress.subscribedAt(this),
    updateAddress = editorCatalogFetchUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("editor-catalog-fetch-failed"),
    updateAddressResolver = { routeScope, request: skirout.editor.v1.catalog.CatalogFetchRequest -> MessageAddress.of("${editorCatalogFetchUpdateAddress.render(routeScope).value}.${request.transferId}") },
)

private val editorCatalogWatchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.catalog.invalidate".realmTemplate()
private val editorCatalogWatchUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.catalog.invalidate".realmTemplate()
fun RealmRouteScope.editorCatalogWatch(policy: ResponsePolicy<skirout.editor.v1.catalog.CatalogInvalidated>, updates: ResponseClassifier<skirout.editor.v1.catalog.CatalogInvalidated>) = skirWatchContract(
    method = WatchEditorCatalog, updateSerializer = skirout.editor.v1.catalog.CatalogInvalidated.serializer,
    name = OperationName.of("editor.catalog.invalidate"), requestAddress = editorCatalogWatchRequestAddress.subscribedAt(this),
    updateAddress = editorCatalogWatchUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("editor-catalog-invalidate-failed"),
)

private val editorValuePrepareRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.creation.prepare".realmTemplate()
fun RealmRouteScope.editorValuePrepare(policy: ResponsePolicy<skirout.editor.v1.catalog.PrepareValueResult>) = skirUnaryContract(
    method = PrepareValue, name = OperationName.of("editor.creation.prepare"),
    address = editorValuePrepareRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-creation-prepare-failed"),
)

private val editorPresentationSearchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.presentation.search".realmTemplate()
private val editorPresentationSearchUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.presentation.search".realmTemplate()
fun RealmRouteScope.editorPresentationSearch(policy: ResponsePolicy<skirout.editor.v1.search.RealmPresentationSearchUpdate>, updates: ResponseClassifier<skirout.editor.v1.search.RealmPresentationSearchUpdate>) = skirWatchContract(
    method = WatchRealmPresentationSearch, updateSerializer = skirout.editor.v1.search.RealmPresentationSearchUpdate.serializer,
    name = OperationName.of("editor.presentation.search"), requestAddress = editorPresentationSearchRequestAddress.subscribedAt(this),
    updateAddress = editorPresentationSearchUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("editor-presentation-search-failed"),
)

private val editorPresentationSearchCancelRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.presentation.search.cancel".realmTemplate()
fun RealmRouteScope.editorPresentationSearchCancel(policy: ResponsePolicy<skirout.editor.v1.search.CancelRealmPresentationSearchResult>) = skirUnaryContract(
    method = CancelRealmPresentationSearch, name = OperationName.of("editor.presentation.search.cancel"),
    address = editorPresentationSearchCancelRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-presentation-search-cancel-failed"),
)

private val editorCapabilityComputationInvokeRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.capability.computation.invoke".realmTemplate()
fun RealmRouteScope.editorCapabilityComputationInvoke(policy: ResponsePolicy<skirout.editor.v1.capability.ComputationResult>) = skirUnaryContract(
    method = InvokeRealmComputation, name = OperationName.of("editor.capability.computation.invoke"),
    address = editorCapabilityComputationInvokeRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-capability-computation-invoke-failed"),
)

private val editorCapabilityCommandInvokeRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.capability.command.invoke".realmTemplate()
fun RealmRouteScope.editorCapabilityCommandInvoke(policy: ResponsePolicy<skirout.editor.v1.capability.CommandResult>) = skirUnaryContract(
    method = InvokeRealmCommand, name = OperationName.of("editor.capability.command.invoke"),
    address = editorCapabilityCommandInvokeRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-capability-command-invoke-failed"),
)

private val authoringStateQueryRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.state.query".realmTemplate()
private val authoringStateQueryUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.state.query".realmTemplate()
fun RealmRouteScope.authoringStateQuery(policy: ResponsePolicy<skirout.editor.v1.authoring.QueryAuthoringStateResponse>, updates: ResponseClassifier<skirout.editor.v1.authoring.QueryAuthoringStateResponse>) = skirWatchContract(
    method = QueryAuthoringState, updateSerializer = skirout.editor.v1.authoring.QueryAuthoringStateResponse.serializer,
    name = OperationName.of("editor.authoring.state.query"), requestAddress = authoringStateQueryRequestAddress.subscribedAt(this),
    updateAddress = authoringStateQueryUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("editor-authoring-state-query-failed"),
    updateAddressResolver = { routeScope, request: skirout.editor.v1.authoring.QueryAuthoringStateRequest -> MessageAddress.of("${authoringStateQueryUpdateAddress.render(routeScope).value}.${request.transferId}") },
)

private val authoringEditCommitRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.edit.commit".realmTemplate()
fun RealmRouteScope.authoringEditCommit(policy: ResponsePolicy<skirout.editor.v1.authoring.CommitPreparedEditResponse>) = skirUnaryContract(
    method = CommitPreparedEdit, name = OperationName.of("editor.authoring.edit.commit"),
    address = authoringEditCommitRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-authoring-edit-commit-failed"),
)

private val authoringTypePreviewRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.type.preview".realmTemplate()
fun RealmRouteScope.authoringTypePreview(policy: ResponsePolicy<skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse>) = skirUnaryContract(
    method = PreviewTypeArgumentChange, name = OperationName.of("editor.authoring.type.preview"),
    address = authoringTypePreviewRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-authoring-type-preview-failed"),
)

private val authoringTypeCommitRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.type.commit".realmTemplate()
fun RealmRouteScope.authoringTypeCommit(policy: ResponsePolicy<skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse>) = skirUnaryContract(
    method = PrepareTypeArgumentChange, name = OperationName.of("editor.authoring.type.commit"),
    address = authoringTypeCommitRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-authoring-type-commit-failed"),
)

private val authoringSearchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.search".realmTemplate()
fun RealmRouteScope.authoringSearch(policy: ResponsePolicy<skirout.editor.v1.authoring.SearchAuthoringResponse>) = skirUnaryContract(
    method = SearchAuthoring, name = OperationName.of("editor.authoring.search"),
    address = authoringSearchRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-authoring-search-failed"),
)

private val authoringChangedAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.changed".realmTemplate()
val RealmRouteScope.authoringChanged get() = EventContract(
    OperationName.of("editor.authoring.changed"), authoringChangedAddress,
    skirout.editor.v1.authoring.AuthoringChanged.serializer.asPayloadCodec(), ErrorSlug.of("editor-authoring-changed-failed"),
)

private val authoringCompiledQueryRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.compiled.query".realmTemplate()
private val authoringCompiledQueryUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.compiled.query".realmTemplate()
fun RealmRouteScope.authoringCompiledQuery(policy: ResponsePolicy<skirout.editor.v1.compiled_content.QueryPublishedContentResponse>, updates: ResponseClassifier<skirout.editor.v1.compiled_content.QueryPublishedContentResponse>) = skirWatchContract(
    method = QueryPublishedContent, updateSerializer = skirout.editor.v1.compiled_content.QueryPublishedContentResponse.serializer,
    name = OperationName.of("editor.authoring.compiled.query"), requestAddress = authoringCompiledQueryRequestAddress.subscribedAt(this),
    updateAddress = authoringCompiledQueryUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("editor-authoring-compiled-query-failed"),
    updateAddressResolver = { routeScope, request: skirout.editor.v1.compiled_content.QueryPublishedContentRequest -> MessageAddress.of("${authoringCompiledQueryUpdateAddress.render(routeScope).value}.${request.transferId}") },
)

private val authoringCompiledChangedAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.compiled.changed".realmTemplate()
val RealmRouteScope.authoringCompiledChanged get() = EventContract(
    OperationName.of("editor.authoring.compiled.changed"), authoringCompiledChangedAddress,
    skirout.editor.v1.compiled_content.CompiledContentChanged.serializer.asPayloadCodec(), ErrorSlug.of("editor-authoring-compiled-changed-failed"),
)

private val authoringCompiledStatusQueryRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.compiled.status.query".realmTemplate()
fun RealmRouteScope.authoringCompiledStatusQuery(policy: ResponsePolicy<skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse>) = skirUnaryContract(
    method = QueryCompiledResourceStatus, name = OperationName.of("editor.authoring.compiled.status.query"),
    address = authoringCompiledStatusQueryRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-authoring-compiled-status-query-failed"),
)

private val authoringPublishRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.publish".realmTemplate()
fun RealmRouteScope.authoringPublish(policy: ResponsePolicy<skirout.editor.v1.publication.PublishAuthoringResponse>) = skirUnaryContract(
    method = PublishAuthoring, name = OperationName.of("editor.authoring.publish"),
    address = authoringPublishRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("editor-authoring-publish-failed"),
)

private val authoringPublicationWatchRequestAddress = "service.to.{realm}.organization.{organization}.realm.editor.authoring.publication.watch".realmTemplate()
private val authoringPublicationWatchUpdateAddress = "service.from.{realm}.organization.{organization}.realm.editor.authoring.publication.watch".realmTemplate()
fun RealmRouteScope.authoringPublicationWatch(policy: ResponsePolicy<skirout.editor.v1.publication.PublicationReport>, updates: ResponseClassifier<skirout.editor.v1.publication.PublicationReport>) = skirWatchContract(
    method = WatchPublication, updateSerializer = skirout.editor.v1.publication.PublicationReport.serializer,
    name = OperationName.of("editor.authoring.publication.watch"), requestAddress = authoringPublicationWatchRequestAddress.subscribedAt(this),
    updateAddress = authoringPublicationWatchUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("editor-authoring-publication-watch-failed"),
)

private val sharedCatalogFetchRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.catalog.fetch".realmTemplate()
fun RealmRouteScope.sharedCatalogFetch(policy: ResponsePolicy<skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse>) = skirUnaryContract(
    method = FetchSharedArtifactCatalog, name = OperationName.of("shared.catalog.fetch"),
    address = sharedCatalogFetchRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("shared-catalog-fetch-failed"),
)

private val sharedPublishRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.publish".realmTemplate()
fun RealmRouteScope.sharedPublish(policy: ResponsePolicy<skirout.service.v1.artifact.PublishSharedArtifactResponse>) = skirUnaryContract(
    method = PublishSharedArtifact, name = OperationName.of("shared.publish"),
    address = sharedPublishRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("shared-publish-failed"),
)

private val sharedBlobMetadataRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.metadata".realmTemplate()
fun RealmRouteScope.sharedBlobMetadata(policy: ResponsePolicy<skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse>) = skirUnaryContract(
    method = FetchArtifactBlobMetadata, name = OperationName.of("shared.blob.metadata"),
    address = sharedBlobMetadataRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("shared-blob-metadata-failed"),
)

private val sharedBlobReadRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.read".realmTemplate()
fun RealmRouteScope.sharedBlobRead(policy: ResponsePolicy<skirout.service.v1.artifact.ReadArtifactBlobResponse>) = skirUnaryContract(
    method = ReadArtifactBlob, name = OperationName.of("shared.blob.read"),
    address = sharedBlobReadRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("shared-blob-read-failed"),
)

private val sharedBlobBeginRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.begin".realmTemplate()
fun RealmRouteScope.sharedBlobBegin(policy: ResponsePolicy<skirout.service.v1.artifact.BeginArtifactBlobWriteResponse>) = skirUnaryContract(
    method = BeginArtifactBlobWrite, name = OperationName.of("shared.blob.begin"),
    address = sharedBlobBeginRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("shared-blob-begin-failed"),
)

private val sharedBlobWriteRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.write".realmTemplate()
fun RealmRouteScope.sharedBlobWrite(policy: ResponsePolicy<skirout.service.v1.artifact.WriteArtifactBlobChunkResponse>) = skirUnaryContract(
    method = WriteArtifactBlobChunk, name = OperationName.of("shared.blob.write"),
    address = sharedBlobWriteRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("shared-blob-write-failed"),
)

private val sharedBlobCompleteRequestAddress = "service.to.{realm}.organization.{organization}.realm.shared.blob.complete".realmTemplate()
fun RealmRouteScope.sharedBlobComplete(policy: ResponsePolicy<skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse>) = skirUnaryContract(
    method = CompleteArtifactBlobWrite, name = OperationName.of("shared.blob.complete"),
    address = sharedBlobCompleteRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("shared-blob-complete-failed"),
)
