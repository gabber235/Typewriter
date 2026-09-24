package com.typewritermc.library

import com.typewritermc.authoring.AuthoringSearchContext
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.PresentationSpec
import com.typewritermc.presentation.TypewriterPresentation
import com.typewritermc.presentation.asStringExpression
import com.typewritermc.presentation.authoringSubjectLayout
import com.typewritermc.presentation.collectionGraph
import com.typewritermc.presentation.rolePresentation
import com.typewritermc.presentation.section
import com.typewritermc.presentation.subjectLayout
import com.typewritermc.presentation.surface
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.PresentationRole

@TypewriterPresentation(roles = [PresentationRole.EDITOR])
context(context: PresentationBuildContext)
fun coreBookEditor(): PresentationSpec<Book> = bookEditor(context)

@TypewriterPresentation(roles = [PresentationRole.CREATION])
context(context: PresentationBuildContext)
fun coreBookCreation(): PresentationSpec<Book> = bookCreation(context)

@TypewriterPresentation(roles = [PresentationRole.REFERENCE_SUMMARY, PresentationRole.REFERENCE_OPTION, PresentationRole.INSPECTOR_HEADER])
context(context: PresentationBuildContext)
fun coreBookReference(): PresentationSpec<Book> = bookSubjectRole(context, "book.reference")

@TypewriterPresentation(roles = [PresentationRole.AUTHORING_RESULT])
context(context: PresentationBuildContext)
fun coreBookAuthoring(): PresentationSpec<Book> = bookAuthoringRole(context, "book.authoring.result")

private fun bookEditor(context: PresentationBuildContext): PresentationSpec<Book> =
    context(context) {
        rolePresentation<Book>("book.editor") {
            val content = editableInput<Book>("content")
            section("title", "Title") { defaultEditor(content.field(Book::title)) }
            section("icon", "Icon") { defaultEditor(content.field(Book::icon)) }
            section("color", "Color") { defaultEditor(content.field(Book::color)) }
            section("tags", "Direct Tags") { defaultEditor(content.field(Book::tags)) }
            section("effective-tags", "Effective Tags", initiallyExpanded = true) {
                collectionGraph(
                    collection = tagCollection,
                    roots = content.field(Book::tags),
                    relation = tagInheritanceRelation,
                    label = TagCollectionRow::name,
                    color = TagCollectionRow::color,
                )
            }
        }
    }

private fun bookCreation(context: PresentationBuildContext): PresentationSpec<Book> =
    context(context) {
        rolePresentation<Book>("book.creation") {
            val content = editableInput<Book>("content")
            section("title", "Title") { defaultEditor(content.field(Book::title)) }
            section("icon", "Icon") { defaultEditor(content.field(Book::icon)) }
            section("color", "Color") { defaultEditor(content.field(Book::color)) }
            section("tags", "Direct Tags") { defaultEditor(content.field(Book::tags)) }
        }
    }

private fun bookSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Book> =
    context(context) {
        rolePresentation<Book>(name) {
            val content = input<Book>("content")
            input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            surface(content.field(Book::color).expression()) {
                subjectLayout(content.field(Book::icon), content.field(Book::title).asStringExpression())
            }
        }
    }

private fun bookAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Book> =
    context(context) {
        rolePresentation<Book>(name) {
            val content = input<Book>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                content.field(Book::title).asStringExpression(),
                searchContext,
            )
        }
    }
