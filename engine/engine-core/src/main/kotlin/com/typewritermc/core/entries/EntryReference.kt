package com.typewritermc.core.entries

import org.koin.java.KoinJavaComponent
import kotlin.reflect.KClass

inline fun <reified E : Entry> emptyRef() = Ref("", E::class)

inline fun <reified E : Entry> E.ref() = Ref(id, E::class)

/**
 * A reference to an entry. This is used to reference an entry from another entry.
 *
 * @param E The type of the entry that this reference points to.
 */
class Ref<E : Entry>(
    val id: String,
    private val klass: KClass<E>
) {
    val isSet: Boolean
        get() = id.isNotBlank()

    val entry: E? by lazy(LazyThreadSafetyMode.NONE) {
        if (!isSet) return@lazy null
        Query.findById(klass, id)
    }

    fun get(): E? = entry


    override fun toString(): String {
        val entry = entry ?: return "Ref<${klass.simpleName}>(NOT SET)"
        return "Ref<${entry::class.simpleName}>($id)"
    }


    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as Ref<*>

        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}

fun <E : Entry> List<Ref<E>>.get(): List<E> = mapNotNull { it.get() }

val Ref<out Entry>.pageId: String?
    get() = KoinJavaComponent.get<Library>(Library::class.java)
        .pages
        .firstNotNullOfOrNull { page ->
            if (page.entries.none { it.id == id }) return@firstNotNullOfOrNull null
            page.id
        }