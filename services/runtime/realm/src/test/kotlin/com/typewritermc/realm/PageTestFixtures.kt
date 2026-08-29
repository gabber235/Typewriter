package com.typewritermc.realm

import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageCatalog
import com.typewritermc.pages.PageCatalogEntry
import com.typewritermc.pages.PageDescriptor
import com.typewritermc.pages.ResolvedPageEditorDefinition
import com.typewritermc.types.Color
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeId
import skirout.kernel.v1.page_kind.PageKindId as SkirPageKindId
import skirout.kernel.v1.page_kind.PageKindRef as SkirPageKindRef

internal object TestPageKinds {
    val SEQUENCE = kind("019d3a87001070008000000000000010")
    val STATIC = kind("019d3a87001170008000000000000011")
    val SCENE = kind("019d3a87001270008000000000000012")
    val MANIFEST = kind("019d3a87001370008000000000000013")
    val UNKNOWN = kind("019d3a87009970008000000000000099")

    private fun kind(id: String) = SkirPageKindRef(id = SkirPageKindId(value = id), revision = 1)
}

internal fun testPageCatalog(): PageCatalog =
    PageCatalog(
        entries =
            listOf(
                "019d3a87001070008000000000000010",
                "019d3a87001170008000000000000011",
                "019d3a87001270008000000000000012",
                "019d3a87001370008000000000000013",
            ).map { id ->
                PageCatalogEntry(
                    originArtifactId = "test",
                    sourcePart = "test",
                    descriptor =
                        PageDescriptor(
                            kind = PageKindRef(PageKindId(DeclaredTypeId.parse(id)), 1),
                            name = "Test Page",
                            description = null,
                            icon = Icon.parse("material-symbols:test-tube"),
                            color = Color.parseRgb("#000000"),
                            editor =
                                ResolvedPageEditorDefinition.Graph(
                                    GraphDirection.LEFT_TO_RIGHT,
                                    listOf(ResolvedTypeRef(TypeId.Qualified("test", "Element"), 1)),
                                ),
                        ),
                )
            },
        diagnostics = emptyList(),
    )
