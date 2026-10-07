package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ComputeVar
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.region.shape.ConeShape
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.PolygonShape
import com.typewritermc.region.shape.SphereShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

class RegionDefinitionSpec : FunSpec({
    val world = World("00000000-0000-0000-0000-000000000000")

    test("an inline definition is named by where it stands") {
        val inline = RegionDefinitionData(origin = ConstVar(Position(world, 128.4, 71.9, -33.2)))

        inline.describeInLog() shouldBe "The inline region at 128, 71, -34"
    }

    test("an inline definition whose origin is a variable is named without one") {
        val inline = RegionDefinitionData(origin = ComputeVar { _, _ -> Position(world, 0.0, 0.0, 0.0) })

        inline.describeInLog() shouldContain "inline region"
    }

    test("a shape describing no volume is not usable") {
        PolygonShape(points = emptyList()).usable shouldBe false
        PolygonShape(
            points = listOf(Vector(0.0, 0.0, 0.0), Vector(1.0, 0.0, 0.0), Vector(2.0, 0.0, 0.0)),
        ).usable shouldBe false
        CuboidShape(halfX = 5.0, halfY = 0.0, halfZ = 5.0).usable shouldBe false
        SphereShape(radius = 0.0).usable shouldBe false
        ConeShape(length = 0.0).usable shouldBe false
    }

    test("a shape a builder could stand in is usable") {
        PolygonShape(
            points = listOf(Vector(0.0, 0.0, 0.0), Vector(4.0, 0.0, 0.0), Vector(0.0, 0.0, 4.0)),
        ).usable shouldBe true
        CuboidShape(halfX = 0.5, halfY = 0.5, halfZ = 0.5).usable shouldBe true
        SphereShape(radius = 0.5).usable shouldBe true
    }
})
