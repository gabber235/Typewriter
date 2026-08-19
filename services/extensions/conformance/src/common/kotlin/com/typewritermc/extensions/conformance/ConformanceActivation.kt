package com.typewritermc.extensions.conformance

import com.typewritermc.extensions.ExtensionActivation
import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import com.typewritermc.extensions.TypewriterActivator

object ConformanceActivation : ExtensionActivation {
    override fun close() = Unit
}

abstract class ConformanceActivator : ExtensionActivator {
    override fun activate(context: ExtensionActivationContext): ExtensionActivation = ConformanceActivation
}

@TypewriterActivator("common")
class CommonConformanceActivator : ConformanceActivator()

class ConformanceFailureActivator : ExtensionActivator {
    override fun activate(context: ExtensionActivationContext): ExtensionActivation = error("conformance activation failure")
}
