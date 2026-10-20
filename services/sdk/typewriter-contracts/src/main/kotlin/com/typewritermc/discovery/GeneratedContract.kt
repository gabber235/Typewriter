package com.typewritermc.discovery

import kotlin.reflect.KClass

/**
 * Marks an interface generated for [target]. Objects implementing it receive a generated provider adapter of
 * [kind]. Codegen applies this annotation; hand written interfaces never receive adapters.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class GeneratedContract(
    val kind: Kind,
    val target: KClass<*>,
) {
    /** The contracts an authored object can fulfil; each produces one provider of [providerKind]. */
    enum class Kind(
        val providerKind: GeneratedProviderKind,
        val suffix: String,
    ) {
        Configuration(GeneratedProviderKind.Configuration, "Configuration"),
        Presentation(GeneratedProviderKind.Presentation, "Presentation"),
        Check(GeneratedProviderKind.Check, "Check"),
        Operations(GeneratedProviderKind.ResourceOperation, "Operations"),
    }
}
