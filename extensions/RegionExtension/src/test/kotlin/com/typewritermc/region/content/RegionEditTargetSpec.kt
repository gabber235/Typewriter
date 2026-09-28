package com.typewritermc.region.content

import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.entries.audience.InRegionAudienceEntry
import com.typewritermc.region.entries.definition.SphereRegionDefinitionEntry
import com.typewritermc.region.shape.SphereShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeSameInstanceAs

class RegionEditTargetSpec : FunSpec({
    test("a definition entry holds its geometry at the top level") {
        val entry = SphereRegionDefinitionEntry(id = "sphere", name = "Sphere", radius = 5.0)
        val target = regionEditTarget(entry, "origin").shouldNotBeNull()

        target.entryId shouldBe "sphere"
        target.placementPath shouldBe ""
        target.shapePath shouldBe ""
        target.definitionOf(entry) shouldBeSameInstanceAs entry
    }

    test("an inline definition holds its geometry behind the field that owns it") {
        val region = RegionDefinitionData(shape = SphereShape(3.0))
        val entry = InRegionAudienceEntry(id = "audience", name = "Audience", region = region)
        val target = regionEditTarget(entry, "region.value.origin").shouldNotBeNull()

        target.entryId shouldBe "audience"
        target.placementPath shouldBe "region.value."
        target.shapePath shouldBe "region.value.shape.value."
        target.definitionOf(entry) shouldBeSameInstanceAs region
    }

    test("a referenced region has no inline definition to edit") {
        val entry = InRegionAudienceEntry(id = "audience", region = RegionReferenceData())
        val target = regionEditTarget(entry, "region.value.origin").shouldNotBeNull()

        target.definitionOf(entry).shouldBeNull()
    }

    test("a field path naming no field of the entry is not an edit target") {
        val entry = InRegionAudienceEntry(id = "audience", region = RegionDefinitionData())

        regionEditTarget(entry, "origin").shouldBeNull()
        regionEditTarget(entry, "missing.value.origin").shouldBeNull()
    }
})
