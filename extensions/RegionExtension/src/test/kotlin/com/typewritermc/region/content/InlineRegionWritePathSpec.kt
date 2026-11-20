package com.typewritermc.region.content

import com.typewritermc.core.serialization.createDataSerializerGson
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.changePathValue
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.loader.serializers.ColorSerializer
import com.typewritermc.engine.paper.loader.serializers.EntryReferenceSerializer
import com.typewritermc.engine.paper.loader.serializers.PositionSerializer
import com.typewritermc.engine.paper.loader.serializers.VarSerializer
import com.typewritermc.engine.paper.loader.serializers.VectorSerializer
import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.entries.audience.InRegionAudienceEntry
import com.typewritermc.region.shape.SphereShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

/**
 * The editor stages field paths and the staging manager writes them into the entry's json.
 * This walks that whole round trip for an inline definition, so the prefixes the editor
 * builds are checked against the serializer that has to read them back, not against a
 * hand written expectation of what the json looks like.
 */
class InlineRegionWritePathSpec : FunSpec({
    val gson = createDataSerializerGson(
        listOf(
            VarSerializer(),
            PositionSerializer(),
            VectorSerializer(),
            ColorSerializer(),
            EntryReferenceSerializer(),
        ),
    )

    test("an applied edit lands on the inline definition the runtime reads back") {
        val entry = InRegionAudienceEntry(
            id = "audience",
            name = "Audience",
            region = RegionDefinitionData(shape = SphereShape(1.0)),
        )
        val target = regionEditTarget(entry, "region.value.origin").shouldNotBeNull()

        val json = gson.toJsonTree(entry)
        val origin = Position(World("world"), 10.0, 64.0, -5.0)
        json.changePathValue(target.placementPath + "origin", gson.toJsonTree(origin))
        json.changePathValue(target.shapePath + "radius", gson.toJsonTree(7.5))

        val updated = gson.fromJson(json, InRegionAudienceEntry::class.java)
        val definition = updated.region.shouldBeInstanceOf<RegionDefinitionData>()
        (definition.origin as ConstVar).value shouldBe origin
        definition.buildShape() shouldBe SphereShape(7.5)
    }
})
