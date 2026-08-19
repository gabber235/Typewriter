package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes

class RealmRouteFactory(
    private val books: BookRepository,
    private val pages: PageRepository,
    private val tags: TagRepository,
    private val editorCatalog: RealmEditorCatalogSource,
    private val presentationSearch: RealmPresentationSearchSource,
) {
    fun create(address: RealmAddress): CommunicatorRoutes {
        val contracts = LibraryContracts(address)
        val bookRoutes = BookRoutes(books, tags, contracts, address)
        val pageRoutes = PageRoutes(pages, books, contracts, address)
        val tagRoutes = TagRoutes(tags, contracts, address)
        val editorCatalogRoutes = EditorCatalogRoutes(editorCatalog, contracts, address)
        val presentationSearchRoutes = RealmPresentationSearchRoutes(presentationSearch, contracts, address)
        return communicatorRoutes {
            bookRoutes.register(this)
            pageRoutes.register(this)
            tagRoutes.register(this)
            editorCatalogRoutes.register(this)
            presentationSearchRoutes.register(this)
        }
    }
}
