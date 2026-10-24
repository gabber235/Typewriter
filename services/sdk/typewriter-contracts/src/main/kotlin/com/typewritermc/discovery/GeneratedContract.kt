package com.typewritermc.discovery

import kotlin.reflect.KClass

/**
 * Marks an interface generated for [target]. Objects implementing it receive a generated provider adapter of
 * [kind]. Codegen applies this annotation to the contracts it generates per type. The only hand written carriers are
 * the root contracts `ResourceDisplay` and `ResourceOperation`, whose [target] is the unpublished `Resource` marker
 * and so applies to any resource.
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
        Operation(GeneratedProviderKind.ResourceOperation, "Operation"),
        Display(GeneratedProviderKind.ResourceDisplay, "Display"),
    }
}
