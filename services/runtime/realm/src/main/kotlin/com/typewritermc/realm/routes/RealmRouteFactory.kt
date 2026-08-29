package com.typewritermc.realm.routes

import com.typewritermc.elements.ElementTypeId
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.compiler.CompiledContentRepository
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.ElementBatchResult
import com.typewritermc.realm.repository.ElementRepository
import com.typewritermc.realm.repository.LibraryBatchRepository
import com.typewritermc.realm.repository.PageDocumentRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.TypeGraph

class RealmRouteFactory(
    private val books: BookRepository,
    private val pages: PageRepository,
    private val tags: TagRepository,
    private val libraryBatches: LibraryBatchRepository,
    private val elements: ElementRepository,
    private val elementTypeGraphs: () -> Map<ElementTypeId, TypeGraph>,
    private val pageDocuments: PageDocumentRepository,
    private val compiledContent: CompiledContentRepository,
    private val editorCatalog: RealmEditorCatalogSource,
    private val pageDefinitions: PageCatalog,
    private val presentationSearch: RealmPresentationSearchSource,
    private val capabilityInvocations: RealmCapabilityInvocationSource? = null,
    private val onElementBatchCommitted: (ElementBatchResult.Success, Boolean) -> Unit = { _, _ -> },
    private val pageDocumentInvalidations: PageDocumentInvalidationEvents? = null,
    private val libraryInvalidations: LibraryInvalidationEvents? = null,
    private val compiledContentActivations: CompiledContentActivationEvents? = null,
    private val onCompilationInvalidated: () -> Unit = {},
) {
    fun create(address: RealmAddress): CommunicatorRoutes {
        val contracts = LibraryContracts(address)
        pageDocumentInvalidations?.configure(contracts, address)
        libraryInvalidations?.configure(contracts, address)
        compiledContentActivations?.configure(contracts, address)
        val bookRoutes = BookRoutes(books, contracts)
        val pageRoutes = PageRoutes(pages, books, contracts)
        val tagRoutes = TagRoutes(tags, contracts)
        val libraryBatchRoutes =
            LibraryBatchRoutes(libraryBatches, pageDefinitions, contracts) { invalidated ->
                if (invalidated) onCompilationInvalidated()
            }
        val pageDocumentRoutes = PageDocumentRoutes(pageDocuments, contracts)
        val libraryInvalidationRoutes = LibraryInvalidationRoutes(pageDocuments, contracts)
        val compiledContentRoutes = CompiledContentRoutes(compiledContent, contracts)
        val elementRoutes = ElementBatchRoutes(elements, elementTypeGraphs, contracts, onElementBatchCommitted)
        val editorCatalogRoutes = EditorCatalogRoutes(editorCatalog, contracts, address)
        val presentationSearchRoutes = RealmPresentationSearchRoutes(presentationSearch, contracts, address)
        val capabilityInvocationRoutes = capabilityInvocations?.let { RealmCapabilityInvocationRoutes(it, contracts) }
        return communicatorRoutes {
            bookRoutes.register(this)
            pageRoutes.register(this)
            tagRoutes.register(this)
            libraryBatchRoutes.register(this)
            pageDocumentRoutes.register(this)
            libraryInvalidationRoutes.register(this)
            compiledContentRoutes.register(this)
            elementRoutes.register(this)
            editorCatalogRoutes.register(this)
            presentationSearchRoutes.register(this)
            capabilityInvocationRoutes?.register(this)
        }
    }
}
