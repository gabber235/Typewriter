package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.PageRepository
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.routing.NatsDispatcher
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import com.typewritermc.services.libs.communicator.routing.natsRouting
import com.typewritermc.services.libs.registrar.RegistrarQualifier
import com.typewritermc.services.libs.utils.DeferredProvider
import kotlinx.coroutines.CoroutineScope
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

class NatsDispatcherFactory(
    private val messageBusProvider: DeferredProvider<MessageBus>,
    private val routes: List<NatsRouting.() -> Unit>,
    private val scope: CoroutineScope
) {
    fun create(): NatsDispatcher {
        val messageBus = messageBusProvider.getOrNull()
            ?: error("MessageBus not yet available. Ensure ServiceRegistrar.initialize() completed.")
        return NatsDispatcher(
            routing = natsRouting(messageBus) {
                routes.forEach { it.invoke(this) }
            },
            scope = scope
        )
    }
}

val REALM_ROUTES_MODULE = module {
    single { RealmRoutes() }
    single { TagRoutes(get<TagRepository>()) }
    single { BookRoutes(get<BookRepository>()) }
    single { PageRoutes(get<PageRepository>()) }

    single {
        NatsDispatcherFactory(
            messageBusProvider = get(named(RegistrarQualifier.MESSAGE_BUS)),
            routes = listOf(
                get<RealmRoutes>().configure(),
                get<TagRoutes>().configure(),
                get<BookRoutes>().configure(),
                get<PageRoutes>().configure()
            ),
            scope = get()
        )
    }
}
