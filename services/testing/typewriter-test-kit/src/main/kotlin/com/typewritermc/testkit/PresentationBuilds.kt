@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.testkit

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationBuildResult
import com.typewritermc.presentation.PresentationBuildScope
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.use
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ScalarKind

/** A text subject in a catalog of the standard types and resource ids: the plainest subject a presentation builds over. */
fun textSubject(): CheckedType =
    DefaultCheckedCatalog(CatalogGeneration(value = "text subject"), StandardTypes.definitions + ResourceIdDefinition.definition)
        .ready(ScalarKind.TEXT.use)

/** What [content] builds over [subject] in [role], with a fresh default presentation runtime. */
fun buildPresentation(
    subject: CheckedType = textSubject(),
    role: PresentationRole = PresentationRole.ITEM,
    content: PresentationBuildScope.() -> Unit,
): PresentationBuildResult =
    DefaultPresentationRuntime().build(PresentationBuildBinding(subject.presentationTemplate(), role)) {
        it.content()
    }
