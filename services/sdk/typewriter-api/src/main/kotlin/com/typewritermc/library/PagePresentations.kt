package com.typewritermc.library

import com.typewritermc.authoring.AuthoringSearchContext
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.PresentationSpec
import com.typewritermc.presentation.TypewriterPresentation
import com.typewritermc.presentation.asStringExpression
import com.typewritermc.presentation.authoringSubjectLayout
import com.typewritermc.presentation.rolePresentation
import com.typewritermc.presentation.section
import com.typewritermc.presentation.subjectLayout
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.ResolvedTypeRef

@TypewriterPresentation(roles = [PresentationRole.EDITOR])
context(context: PresentationBuildContext)
fun corePageEditor(): PresentationSpec<Page> = pageEditor(context)

@TypewriterPresentation(roles = [PresentationRole.CREATION])
context(context: PresentationBuildContext)
fun corePageCreation(): PresentationSpec<Page> = pageCreation(context)

@TypewriterPresentation(
    roles = [
        PresentationRole.REFERENCE_SUMMARY,
        PresentationRole.REFERENCE_OPTION,
        PresentationRole.PAGE_TILE,
        PresentationRole.INSPECTOR_HEADER,
    ],
)
context(context: PresentationBuildContext)
fun corePageReference(): PresentationSpec<Page> = pageSubjectRole(context, "page.reference")

@TypewriterPresentation(roles = [PresentationRole.CATALOG_OPTION])
context(context: PresentationBuildContext)
fun corePageCatalog(): PresentationSpec<Page> = pageCatalogRole(context, "page.catalog.option")

@TypewriterPresentation(roles = [PresentationRole.AUTHORING_RESULT])
context(context: PresentationBuildContext)
fun corePageAuthoring(): PresentationSpec<Page> = pageAuthoringRole(context, "page.authoring.result")

private fun pageEditor(context: PresentationBuildContext): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>("page.editor") {
            val content = editableInput<Page>("content")
            section("book", "Book") { defaultEditor(content.field(Page::book)) }
            section("name", "Name") { defaultEditor(content.field(Page::name)) }
            section("chapter", "Chapter") { defaultEditor(content.field(Page::chapter)) }
            section("priority", "Priority") { defaultEditor(content.field(Page::priority)) }
        }
    }

private fun pageCreation(context: PresentationBuildContext): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>("page.creation") {
            val content = editableInput<Page>("content")
            section("name", "Name") { defaultEditor(content.field(Page::name)) }
            section("chapter", "Chapter") { defaultEditor(content.field(Page::chapter)) }
            section("priority", "Priority") { defaultEditor(content.field(Page::priority)) }
        }
    }

private fun pageSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>(name) {
            val content = input<Page>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Page::name).asStringExpression())
        }
    }

private fun pageCatalogRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>(name) {
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResolvedTypeRef>("identity")
            subjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                descriptor.field(ResourceTypeDescriptor::name).expression(),
            )
        }
    }

private fun pageAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Page> =
    context(context) {
        rolePresentation<Page>(name) {
            val content = input<Page>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                content.field(Page::name).asStringExpression(),
                searchContext,
            )
        }
    }
