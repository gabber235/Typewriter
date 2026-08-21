package com.typewritermc.extensions.conformance

import com.typewritermc.extensions.ExtensionActivation
import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import com.typewritermc.extensions.TypewriterActivator

internal object ConformanceActivation : ExtensionActivation {
    override fun close() = Unit
}

/**
 * Provides the successful no operation activation shared by conformance fixtures in derived source sets.
 *
 * This type is public only because each derived source set compiles as a separate Kotlin module. It is test fixture API,
 * not an extension authoring contract.
 */
abstract class ConformanceActivator : ExtensionActivator {
    override fun activate(context: ExtensionActivationContext): ExtensionActivation = ConformanceActivation
}

@TypewriterActivator("common")
internal class CommonConformanceActivator : ConformanceActivator()

/**
 * Fails activation deliberately so engine conformance tests can verify cleanup and rollback across module boundaries.
 *
 * This type is public only because the conformance engine tests compile in a separate Kotlin module.
 */
class ConformanceFailureActivator : ExtensionActivator {
    override fun activate(context: ExtensionActivationContext): ExtensionActivation = error("conformance activation failure")
}
