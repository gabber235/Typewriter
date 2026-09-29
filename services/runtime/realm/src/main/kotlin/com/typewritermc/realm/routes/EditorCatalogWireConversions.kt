package com.typewritermc.realm.routes

import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.discovery.AuthoringEditorLayout
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.ResolvedType
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.skir.toSkir
import skirout.editor.v1.catalog_presentation.CatalogPresentationSubject
import skirout.editor.v1.catalog.AuthoringEditorLayout as WireEditorLayout
import skirout.editor.v1.catalog.GraphDirection as WireGraphDirection
import skirout.editor.v1.catalog.CatalogTypeView as WireTypeView
import skirout.editor.v1.catalog.TypeDisplay as WireTypeDisplay
import skirout.editor.v1.type_catalog.TypeDefinition as WireTypeDefinition

/** Converts one resolved type and its optional authoring metadata to the editor view. */
internal fun ResolvedType.toSkir(
    encodedDefinition: WireTypeDefinition,
    prototypes: TypePrototypeRegistry,
): WireTypeView {
    val appearance = metadata?.display
    return WireTypeView(
        definition = encodedDefinition,
        display = appearance?.let { WireTypeDisplay(description = it.description, icon = it.icon.toSkir(), color = it.color.toSkir()) },
        editor = metadata?.editor?.toSkir(),
        eligible = canCreate(DiscoveryDomains.Realm),
        ineligibilityReasons = creationReasons(DiscoveryDomains.Realm),
        presentationSubject =
            appearance?.let { display ->
                CatalogPresentationSubject(
                    target = definition.id.toSkir().getOrThrow(),
                    descriptor =
                        prototypes
                            .encode(
                                ResourceTypeDescriptor(
                                    name = definition.displayName,
                                    description = display.description,
                                    icon = display.icon,
                                    color = display.color,
                                ),
                            ).toWire(),
                )
            },
    )
}

private fun AuthoringEditorLayout.toSkir(): WireEditorLayout =
    when (this) {
        is AuthoringEditorLayout.Graph -> WireEditorLayout.createGraph(direction = direction.toSkir())
        AuthoringEditorLayout.Timeline -> WireEditorLayout.createTimeline()
    }

private fun GraphDirection.toSkir(): WireGraphDirection =
    when (this) {
        GraphDirection.LEFT_TO_RIGHT -> WireGraphDirection.LEFT_TO_RIGHT
        GraphDirection.RIGHT_TO_LEFT -> WireGraphDirection.RIGHT_TO_LEFT
        GraphDirection.TOP_TO_BOTTOM -> WireGraphDirection.TOP_TO_BOTTOM
        GraphDirection.BOTTOM_TO_TOP -> WireGraphDirection.BOTTOM_TO_TOP
    }
