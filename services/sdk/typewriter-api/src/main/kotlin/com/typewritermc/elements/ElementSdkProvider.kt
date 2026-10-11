package com.typewritermc.elements

object ElementSdkProvider : ElementConfiguration {
    override fun ElementConfigurationScope.configure() {
        name {
            nonEmpty()
            singleLine()
        }
    }
}
