package com.typewritermc.region.tracker

import com.google.gson.JsonParser
import com.typewritermc.core.serialization.createDataSerializerGson
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.loader.serializers.VectorSerializer
import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.shape.Shape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

/**
 * The engine only classifies a player against a tracker when the player is inside its world
 * AABB, and that AABB comes from the shape's local bounds. An inline definition's shape is
 * the only one that is read from json, so a shape that loses its bounds there silently
 * shrinks the region's reach to nothing without changing where the region draws.
 */
class InlineRegionBoundsSpec : FunSpec({
    val gson = createDataSerializerGson(listOf(VectorSerializer()))

    test("an inline sphere reaches as far as its radius, whatever bounds the json carries") {
        val json = JsonParser.parseString(
            """
            {"case":"sphere_shape","value":{"radius":20.0,"localBounds":{
            "minX":0.0,"minY":0.0,"minZ":0.0,"maxX":0.0,"maxY":0.0,"maxZ":0.0}}}
            """.trimIndent(),
        )
        val shape = gson.fromJson(json, Shape::class.java)

        val definition = RegionDefinitionData(
            origin = ConstVar(Position(World("world"), 100.0, 64.0, -40.0)),
            shape = shape,
        )
        val tracker = RegionTracker(null, definition)
        tracker.refresh()

        val aabb = tracker.cachedAabb.shouldNotBeNull()
        aabb.minX shouldBe 80.0
        aabb.maxX shouldBe 120.0
        aabb.minZ shouldBe -60.0
        aabb.maxZ shouldBe -20.0
    }
})
