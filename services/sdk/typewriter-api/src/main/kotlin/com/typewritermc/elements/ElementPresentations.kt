package com.typewritermc.elements

import com.typewritermc.authoring.AuthoringSearchContext
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.PresentationSpec
import com.typewritermc.presentation.TypewriterPresentation
import com.typewritermc.presentation.authoringSubjectLayout
import com.typewritermc.presentation.rolePresentation
import com.typewritermc.presentation.subjectLayout
import com.typewritermc.types.PresentationRole

@TypewriterPresentation(roles = [PresentationRole.REFERENCE_SUMMARY, PresentationRole.REFERENCE_OPTION, PresentationRole.INSPECTOR_HEADER])
context(context: PresentationBuildContext)
fun coreElementReference(): PresentationSpec<Element> = elementSubjectRole(context, "element.reference")

@TypewriterPresentation(roles = [PresentationRole.CATALOG_OPTION])
context(context: PresentationBuildContext)
fun coreElementCatalog(): PresentationSpec<Element> = elementCatalogRole(context, "element.catalog")

@TypewriterPresentation(roles = [PresentationRole.AUTHORING_RESULT])
context(context: PresentationBuildContext)
fun coreElementAuthoring(): PresentationSpec<Element> = elementAuthoringRole(context, "element.authoring")

@TypewriterPresentation(roles = [PresentationRole.GRAPH_NODE])
context(context: PresentationBuildContext)
fun coreEntryGraph(): PresentationSpec<Entry> = entryGraphRole(context, "entry.graph")

private fun elementSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Element> =
    context(context) {
        rolePresentation<Element>(name) {
            val content = input<Element>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Element::name).expression())
        }
    }

private fun elementCatalogRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Element> =
    context(context) {
        rolePresentation<Element>(name) {
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), descriptor.field(ResourceTypeDescriptor::name).expression())
        }
    }

private fun elementAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Element> =
    context(context) {
        rolePresentation<Element>(name) {
            val content = input<Element>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Element::name).expression(), searchContext)
        }
    }

private fun entryGraphRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Entry> =
    context(context) {
        rolePresentation<Entry>(name) {
            val content = input<Entry>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            adaptiveLeading(
                leading = { icon(descriptor.field(ResourceTypeDescriptor::icon)) },
                center = { text(content.field(Entry::name).expression()) },
            )
        }
    }
