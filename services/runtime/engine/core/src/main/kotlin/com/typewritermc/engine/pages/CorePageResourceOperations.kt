package com.typewritermc.engine.pages

import com.typewritermc.operations.GraphGroupPlacement

object SequencePageResourceOperations : SequencePageOperations {
    override fun SequencePageOperationsScope.operations() {
        placementFor(SequencePageFields.elements, GraphGroupPlacement)
    }
}

object StaticPageResourceOperations : StaticPageOperations {
    override fun StaticPageOperationsScope.operations() {
        placementFor(StaticPageFields.elements, GraphGroupPlacement)
    }
}

object ManifestPageResourceOperations : ManifestPageOperations {
    override fun ManifestPageOperationsScope.operations() {
        placementFor(ManifestPageFields.elements, GraphGroupPlacement)
    }
}
