package com.typewritermc.capability

/** Marks a class whose [RealmCapability] functions codegen publishes as realm capabilities. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class RealmCapabilities

/** Capability kinds of a function inside a [RealmCapabilities] class; each function carries exactly one. */
object RealmCapability {
    @Target(AnnotationTarget.FUNCTION)
    @Retention(AnnotationRetention.BINARY)
    annotation class Search

    @Target(AnnotationTarget.FUNCTION)
    @Retention(AnnotationRetention.BINARY)
    annotation class Computation

    @Target(AnnotationTarget.FUNCTION)
    @Retention(AnnotationRetention.BINARY)
    annotation class Command
}
