package com.typewritermc.pages

import com.typewritermc.discovery.GraphDirection

/** Declares the editor layout of a concrete Page schema at generation time. */
object TypewriterPage {
    @Target(AnnotationTarget.CLASS)
    @Retention(AnnotationRetention.BINARY)
    annotation class Graph(
        val direction: GraphDirection,
    )

    @Target(AnnotationTarget.CLASS)
    @Retention(AnnotationRetention.BINARY)
    annotation class Timeline
}
