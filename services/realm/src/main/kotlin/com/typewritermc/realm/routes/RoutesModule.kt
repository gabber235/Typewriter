package com.typewritermc.realm.routes

import com.typewritermc.realm.RealmQualifier.DATABASE
import com.typewritermc.realm.repository.*
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import com.typewritermc.services.libs.communicator.routing.NatsDispatcher
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import com.typewritermc.services.libs.communicator.routing.natsRouting
import com.typewritermc.services.libs.registrar.RegistrarQualifier
import com.typewritermc.services.libs.registrar.RegistrarQualifier.CREDENTIAL
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.opentelemetry.api.trace.Tracer
import kotlinx.coroutines.CoroutineScope
import org.koin.core.qualifier.named
import org.koin.core.qualifier.qualifier
import org.koin.dsl.module

class NatsDispatcherFactory(
    private val messageBusProvider: DeferredProvider<MessageBus>,
    private val routes: List<NatsRouting.() -> Unit>,
    private val scope: CoroutineScope,
    private val tracer: Tracer
) {
    fun create(): NatsDispatcher {
        val messageBus = messageBusProvider.getOrNull()
            ?: error("MessageBus not yet available. Ensure ServiceRegistrar.initialize() completed.")
        return NatsDispatcher(
            routing = natsRouting(messageBus) {
                routes.forEach { it.invoke(this) }
            },
            scope = scope,
            tracer = tracer
        )
    }
}

val REALM_ROUTES_MODULE = module {
    single { RealmRoutes(get(qualifier(CREDENTIAL)), get<StateProvider<RegistrationState>>()) }
    single { TagRoutes(get<TagRepository>(), get(qualifier(CREDENTIAL)), get<StateProvider<RegistrationState>>()) }
    single { BookRoutes(get<BookRepository>(), get(qualifier(CREDENTIAL)), get<StateProvider<RegistrationState>>()) }
    single { PageRoutes(get<PageRepository>(), get(qualifier(CREDENTIAL)), get<StateProvider<RegistrationState>>()) }

    single<TagRepository> { SurrealTagRepository(get(qualifier(DATABASE))) }
    single<BookRepository> { SurrealBookRepository(get(qualifier(DATABASE))) }
    single<PageRepository> { SurrealPageRepository(get(qualifier(DATABASE))) }

    single {
        NatsDispatcherFactory(
            messageBusProvider = get(named(RegistrarQualifier.MESSAGE_BUS)),
            routes = listOf(
                get<RealmRoutes>().configure(),
                get<TagRoutes>().configure(),
                get<BookRoutes>().configure(),
                get<PageRoutes>().configure()
            ),
            scope = get(),
            tracer = get()
        )
    }
}
