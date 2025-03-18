package com.typewritermc.core.entries

import com.typewritermc.core.books.pages.PageType
import org.koin.java.KoinJavaComponent.get
import kotlin.reflect.KClass
import kotlin.reflect.safeCast

/**
 * A query can be used to search for entries.
 * This is useful for events where you want to invoke all triggers for a specific entry given a query.
 *
 * @param klass The class of the entry.
 */
class Query<E : Entry>(private val klass: KClass<E>) {

    /**
     * Find all entries that match the given a filter
     *
     * Example:
     * ```kotlin
     * val query: Query<SomeEntry> = ...
     * query findWhere { it.someValue == "hello" }
     * ```
     *
     * It can be used in combination with [triggerAllFor] to invoke all triggers for all entries that match the filter.
     * Example:
     * ```kotlin
     * val query: Query<SomeEntry> = ...
     * query findWhere { it.someValue == "hello" } triggerAllFor player
     * ```
     *
     * @param filter The filter to apply to the entries.
     */
    infix fun findWhere(filter: (E) -> Boolean): Sequence<E> = findWhere(klass, filter)

    /**
     * Find the first entry that matches the given a filter
     * @see findWhere
     */
    infix fun firstWhere(filter: (E) -> Boolean): E? = firstWhere(klass, filter)

    /**
     * Find all the entries for the given class.
     *
     * Example:
     * ```kotlin
     * val query: Query<SomeEntry> = ...
     * query.find()
     * ```
     */
    fun find() = findWhere { true }

    /**
     * Find entry by [name].
     *
     * Example:
     * ```kotlin
     * val query: Query<SomeEntry> = ...
     * query findByName "someName"
     * ```
     */
    infix fun findByName(name: String) = firstWhere { it.name == name }

    /**
     * Find entry by [id].
     *
     * Example:
     * ```kotlin
     * val query: Query<SomeEntry> = ...
     * query findById "someId"
     * ```
     */
    infix fun findById(id: String): E? = findById(klass, id)

    /**
     * Find entry all entries that are on the given page [pageId] with the given [filter].
     * @see findWhere
     */
    fun findWhereFromPage(pageId: String, filter: (E) -> Boolean): Sequence<E> =
        findWhereFromPage(klass, pageId, filter)

    companion object {
        /**
         * Find all entries that match the given a filter
         *
         * Example:
         * ```kotlin
         * Query findWhere<SomeEntry> { it.someValue == "hello" }
         * ```
         *
         * It can be used in combination with [triggerAllFor] to invoke all triggers for all entries that match the filter.
         * Example:
         * ```kotlin
         * Query findWhere<SomeEntry> { it.someValue == "hello" } triggerAllFor player
         * ```
         *
         * @param filter The filter to apply to the entries.
         */
        inline infix fun <reified E : Entry> findWhere(noinline filter: (E) -> Boolean): Sequence<E> {
            return findWhere(E::class, filter)
        }

        /**
         * Find all entries that match the given a filter
         *
         * Example:
         * ```kotlin
         * Query.findWhere<SomeEntry>(SomeEntry::class) { it.someValue == "hello" }
         * ```
         *
         * It can be used in combination with [triggerAllFor] to invoke all triggers for all entries that match the filter.
         * Example:
         * ```kotlin
         * Query.findWhere<SomeEntry>(SomeEntry::class) { it.someValue == "hello" } triggerAllFor player
         * ```
         *
         * @param filter The filter to apply to the entries.
         */
        fun <E : Entry> findWhere(klass: KClass<E>, filter: (E) -> Boolean): Sequence<E> {
            return get<Library>(Library::class.java).entries
                .asSequence()
                .filterIsInstance(klass.java)
                .filter(filter)
        }

        /**
         * Find the first entry that matches the given a filter
         * @see findWhere
         */
        inline infix fun <reified E : Entry> firstWhere(noinline filter: (E) -> Boolean): E? {
            return firstWhere(E::class, filter)
        }

        /**
         * Find the first entry that matches the given a filter
         * @see findWhere
         */
        fun <E : Entry> firstWhere(klass: KClass<E>, filter: (E) -> Boolean): E? {
            return get<Library>(Library::class.java).entries
                .asSequence()
                .filterIsInstance(klass.java)
                .filter(filter)
                .firstOrNull()
        }


        /**
         * Find all the entries for the given class.
         *
         * Example:
         * ```kotlin
         * Query.find<SomeEntry>()
         * ```
         */
        inline fun <reified E : Entry> find() = findWhere<E> { true }

        /**
         * Find all the entries for the given class.
         *
         * Example:
         * ```kotlin
         * Query.find<SomeEntry>(SomeEntry::class)
         * ```
         */
        fun <E : Entry> find(klass: KClass<E>) = findWhere(klass) { true }

        /**
         * Find entry by [name].
         *
         * Example:
         * ```kotlin
         * Query findByName<SomeEntry> "someName"
         * ```
         */
        inline infix fun <reified E : Entry> findByName(name: String) = firstWhere<E> { it.name == name }

        /**
         * Find entry by [name].
         *
         * Example:
         * ```kotlin
         * Query.findByName<SomeEntry>(SomeEntry::class, "someName")
         * ```
         */
        fun <E : Entry> findByName(klass: KClass<E>, name: String) = firstWhere(klass) { it.name == name }

        inline infix fun <reified E : Entry> findById(id: String): E? = findById(E::class, id)

        /**
         * Find entry by [id].
         * @see findByName
         */
        fun <E : Entry> findById(klass: KClass<E>, id: String): E? =
            klass.safeCast(get<Library>(Library::class.java).entriesById[id])

        /**
         * Find entry all entries that are on the given page [pageId] with the given [filter].
         * @see findWhere
         */
        inline fun <reified E : Entry> findWhereFromPage(pageId: String, noinline filter: (E) -> Boolean): Sequence<E> {
            return findWhereFromPage(E::class, pageId, filter)
        }

        /**
         * Find entry all entries that are on the given page [pageId] with the given [filter].
         * @see findWhere
         */
        fun <E : Entry> findWhereFromPage(klass: KClass<E>, pageId: String, filter: (E) -> Boolean): Sequence<E> {
            return get<Library>(Library::class.java).pages
                .asSequence()
                .filter { it.id == pageId }
                .flatMap { it.entries }
                .filterIsInstance(klass.java)
                .filter(filter)
        }

        /**
         * Finds all pages which are of the given [type].
         *
         * Example:
         * ```kotlin
         * Query.findPagesOfType(PageType.STATIC)
         * ```
         */
        fun findPagesOfType(type: PageType): Sequence<Page> {
            return get<Library>(Library::class.java).pages
                .asSequence()
                .filter { it.type == type }
        }

        /**
         * Finds a page by its [id].
         *
         * Example:
         * ```kotlin
         * Query.findPageById("some_page_id")
         * ```
         */
        fun findPageById(id: String): Page? {
            return get<Library>(Library::class.java).pages
                .firstOrNull { it.id == id }
        }
    }
}
