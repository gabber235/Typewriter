package com.typewritermc.presentation

import kotlin.reflect.KClass

/** An explicit atomic inspector part, identified by its declaring record contract and local name. */
class PresentationPartKey<Owner : Any>
    @PublishedApi
    internal constructor(
        val ownerClass: KClass<Owner>,
        val name: String,
    )

/** Declares a stable identity for content that descendants may request, replace, or exclude. */
inline fun <reified Owner : Any> presentationPart(name: String): PresentationPartKey<Owner> {
    require(name.isNotBlank()) { "Presentation part names must not be blank." }
    return PresentationPartKey(Owner::class, name)
}

/** Requests the most specific applicable inherited body at this position. */
context(layout: Layout)
operator fun PresentationPartKey<*>.invoke() = layout.part(this)

/** Defines or replaces this atomic part at this position. */
context(layout: Layout)
operator fun PresentationPartKey<*>.invoke(body: Layout.() -> Unit) = layout.part(this, body)
