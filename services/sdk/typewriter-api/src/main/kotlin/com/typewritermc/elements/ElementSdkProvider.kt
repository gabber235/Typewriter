package com.typewritermc.elements

import com.typewritermc.expression.trim
import com.typewritermc.types.PresentationRole

object ElementSdkProvider : ElementConfiguration {
    override fun ElementConfigurationScope.configure() {
        name {
            nonEmpty()
            singleLine()
        }
    }
}

object ElementInspectorPresentation : ElementPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)

    override fun ElementPresentationScope.present() {
        name {
            label("name")
            textInput { onComplete { value.trim() } }
        }
        remainingFields()
    }
}
