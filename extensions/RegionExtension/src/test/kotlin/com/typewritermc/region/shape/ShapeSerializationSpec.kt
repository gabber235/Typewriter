package com.typewritermc.region.shape

import com.google.gson.JsonParser
import com.typewritermc.core.serialization.createDataSerializerGson
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.loader.serializers.VectorSerializer
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

/**
 * An inline region definition is the only place a [Shape] is serialized: a definition entry
 * builds its shape in code. Everything a shape derives from its own fields has to survive
 * that round trip, and must never become a field a user can write.
 */
class ShapeSerializationSpec : FunSpec({
    val gson = createDataSerializerGson(listOf(VectorSerializer()))

    test("a shape writes only the fields that describe it") {
        val json = gson.toJsonTree(SphereShape(5.0), Shape::class.java).asJsonObject

        json["case"].asString shouldBe "sphere_shape"
        json["value"].asJsonObject.keySet() shouldContainExactlyInAnyOrder setOf("radius")
    }

    test("a cone writes only the fields that describe it") {
        val json = gson.toJsonTree(ConeShape(10.0, 30.0), Shape::class.java).asJsonObject

        json["value"].asJsonObject.keySet() shouldContainExactlyInAnyOrder setOf("length", "halfAngleDegrees")
    }

    test("a sphere read back from json derives its bounds from its radius") {
        val json = JsonParser.parseString("""{"case":"sphere_shape","value":{"radius":5.0}}""")

        val shape = gson.fromJson(json, Shape::class.java)

        shape.localBounds shouldBe LocalBounds(-5.0, -5.0, -5.0, 5.0, 5.0, 5.0)
    }

    test("a cone read back from json still classifies its own points") {
        val json = JsonParser.parseString("""{"case":"cone_shape","value":{"length":10.0,"halfAngleDegrees":30.0}}""")

        val shape = gson.fromJson(json, Shape::class.java)

        shape.contains(Vector(0.0, 0.0, 5.0)).shouldBeTrue()
        shape.localBounds.maxZ shouldBe 10.0
    }

    test("bounds saved by an older panel are ignored, not trusted") {
        val json = JsonParser.parseString(
            """
            {"case":"sphere_shape","value":{"radius":5.0,"localBounds":{
            "minX":0.0,"minY":0.0,"minZ":0.0,"maxX":0.0,"maxY":0.0,"maxZ":0.0}}}
            """.trimIndent(),
        )

        val shape = gson.fromJson(json, Shape::class.java)

        shape.localBounds shouldBe LocalBounds(-5.0, -5.0, -5.0, 5.0, 5.0, 5.0)
    }
})
