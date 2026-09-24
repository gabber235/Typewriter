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
import com.typewritermc.types.PresentationRole

@TypewriterPresentation(roles = [PresentationRole.EDITOR])
context(context: PresentationBuildContext)
fun coreTagEditor(): PresentationSpec<Tag> = tagEditor(context)

@TypewriterPresentation(
    roles = [
        PresentationRole.REFERENCE_SUMMARY,
        PresentationRole.REFERENCE_OPTION,
        PresentationRole.GRAPH_NODE,
        PresentationRole.INSPECTOR_HEADER,
    ],
)
context(context: PresentationBuildContext)
fun coreTagReference(): PresentationSpec<Tag> = tagSubjectRole(context, "tag.reference")

@TypewriterPresentation(roles = [PresentationRole.AUTHORING_RESULT])
context(context: PresentationBuildContext)
fun coreTagAuthoring(): PresentationSpec<Tag> = tagAuthoringRole(context, "tag.authoring.result")

private fun tagEditor(context: PresentationBuildContext): PresentationSpec<Tag> =
    context(context) {
        rolePresentation<Tag>("tag.editor") {
            val content = editableInput<Tag>("content")
            section("name", "Name") { defaultEditor(content.field(Tag::name)) }
            section("color", "Color") { defaultEditor(content.field(Tag::color)) }
            section("parents", "Direct Parents") { defaultEditor(content.field(Tag::parents)) }
            section("inheritance", "Inheritance", initiallyExpanded = true) {
                collectionGraph(
                    collection = tagCollection,
                    roots = content.field(Tag::parents),
                    relation = tagInheritanceRelation,
                    label = TagCollectionRow::name,
                    color = TagCollectionRow::color,
                )
            }
            section("placement", "Placement") { defaultEditor(content.field(Tag::placement)) }
        }
    }

private fun tagSubjectRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Tag> =
    context(context) {
        rolePresentation<Tag>(name) {
            val content = input<Tag>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            surface(content.field(Tag::color).expression()) {
                subjectLayout(descriptor.field(ResourceTypeDescriptor::icon), content.field(Tag::name).asStringExpression())
            }
        }
    }

private fun tagAuthoringRole(
    context: PresentationBuildContext,
    name: String,
): PresentationSpec<Tag> =
    context(context) {
        rolePresentation<Tag>(name) {
            val content = input<Tag>("content")
            val descriptor = input<ResourceTypeDescriptor>("descriptor")
            input<ResourceIdentity>("identity")
            val searchContext = input<AuthoringSearchContext>("context")
            authoringSubjectLayout(
                descriptor.field(ResourceTypeDescriptor::icon),
                content.field(Tag::name).asStringExpression(),
                searchContext,
            )
        }
    }
