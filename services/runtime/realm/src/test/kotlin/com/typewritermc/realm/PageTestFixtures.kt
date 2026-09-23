package com.typewritermc.realm

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
                            type = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse(id)), 1),
                            name = "Test Page",
                            description = null,
                            icon = Icon.parse("material-symbols:test-tube"),
                            color = Color.parseRgb("#000000"),
                            editor =
                                ResolvedPageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT),
                        ),
                )
            },
        diagnostics = emptyList(),
    )
