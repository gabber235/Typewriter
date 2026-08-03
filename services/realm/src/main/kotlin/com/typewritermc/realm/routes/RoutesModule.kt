package com.typewritermc.realm.routes

import com.typewritermc.realm.RealmQualifier.DATABASE
import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.SurrealBookRepository
import com.typewritermc.realm.repository.SurrealPageRepository
import com.typewritermc.realm.repository.SurrealTagRepository
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import org.koin.core.qualifier.qualifier
import org.koin.dsl.module

class RealmRouteFactory(
    private val books: BookRepository,
    private val pages: PageRepository,
    private val tags: TagRepository,
) {
    fun create(address: RealmAddress): CommunicatorRoutes {
        val contracts = LibraryContracts(address)
        val bookRoutes = BookRoutes(books, tags, contracts, address)
        val pageRoutes = PageRoutes(pages, books, contracts, address)
        val tagRoutes = TagRoutes(tags, books, contracts, address)
        return communicatorRoutes {
            bookRoutes.register(this)
            pageRoutes.register(this)
            tagRoutes.register(this)
        }
    }
}

val REALM_ROUTES_MODULE =
    module {
        single<TagRepository> { SurrealTagRepository(get(qualifier(DATABASE))) }
        single<BookRepository> { SurrealBookRepository(get(qualifier(DATABASE))) }
        single<PageRepository> { SurrealPageRepository(get(qualifier(DATABASE))) }
        single { RealmRouteFactory(get(), get(), get()) }
    }
