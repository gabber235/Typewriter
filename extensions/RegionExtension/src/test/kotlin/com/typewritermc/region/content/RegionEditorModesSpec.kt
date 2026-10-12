package com.typewritermc.region.content

import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.region.shape.CapsuleShape
import com.typewritermc.region.shape.ConeShape
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.EllipsoidShape
import com.typewritermc.region.shape.PolygonShape
import com.typewritermc.region.shape.SphereShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.mockk
import org.bukkit.entity.Player

class RegionEditorModesSpec : FunSpec({
    val player = mockk<Player>(relaxed = true)
    val context = ContentContext(mapOf("entryId" to "region", "fieldPath" to "origin"))

    test("an inline shape opens the same editor its definition entry would open") {
        regionEditorMode(CuboidShape(), context, player).shouldBeInstanceOf<CuboidRegionContentMode>()
        regionEditorMode(SphereShape(), context, player).shouldBeInstanceOf<SphereRegionContentMode>()
        regionEditorMode(EllipsoidShape(), context, player).shouldBeInstanceOf<EllipsoidRegionContentMode>()
        regionEditorMode(CapsuleShape(), context, player).shouldBeInstanceOf<CapsuleRegionContentMode>()
        regionEditorMode(ConeShape(), context, player).shouldBeInstanceOf<ConeRegionContentMode>()
        regionEditorMode(PolygonShape(), context, player).shouldBeInstanceOf<PolygonRegionContentMode>()
    }
})
