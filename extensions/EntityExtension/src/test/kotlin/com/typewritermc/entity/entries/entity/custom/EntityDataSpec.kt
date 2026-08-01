package com.typewritermc.entity.entries.entity.custom

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.PacketEventsAPI
import com.github.retrooper.packetevents.settings.PacketEventsSettings
import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.entity.entries.data.minecraft.PoseProperty
import com.typewritermc.entity.entries.data.minecraft.living.AgeableProperty
import com.typewritermc.entity.entries.data.minecraft.living.SizeProperty
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import kotlin.reflect.KClass

private fun properties(vararg properties: EntityProperty): Map<KClass<*>, EntityProperty> =
    properties.associateBy<EntityProperty, KClass<*>> { it::class }

/** Naming an [EntityTypes] constant loads the mappings, which are read through the settings and nothing else. */
private fun loadEntityTypes() {
    if (PacketEvents.getAPI() != null) return
    val api = mockk<PacketEventsAPI<Any>>(relaxed = true)
    every { api.settings } returns PacketEventsSettings()
    PacketEvents.setAPI(api)
}

class EntityDataSpec : FunSpec({
    beforeSpec { loadEntityTypes() }

    test("a row for the pose beats the row for the type on its own") {
        EntityTypes.WARDEN.state(properties(PoseProperty(EntityPose.ROARING))).height shouldBe 2.9
        EntityTypes.WARDEN.state(properties(PoseProperty(EntityPose.SNIFFING))).height shouldBe 2.9
        EntityTypes.WARDEN.state(properties(PoseProperty(EntityPose.DIGGING))).height shouldBe 1.0
    }

    test("a size row applies to its own size, not to every size below it") {
        EntityTypes.SLIME.state(properties(SizeProperty(1))).height shouldBe 0.52
        EntityTypes.SLIME.state(properties(SizeProperty(2))).height shouldBe 1.04
        EntityTypes.SLIME.state(properties(SizeProperty(4))).height shouldBe 2.08
    }

    test("a size with no row of its own rounds up to the next one that fits") {
        EntityTypes.MAGMA_CUBE.state(properties(SizeProperty(3))).height shouldBe 2.08
    }

    test("a pose the type has no row for falls back on standing") {
        val standing = EntityTypes.PLAYER.state(properties(PoseProperty(EntityPose.STANDING)))
        EntityTypes.PLAYER.state(properties(PoseProperty(EntityPose.CROAKING))).height shouldBe standing.height
    }

    test("a manual row wins over the generated row it corrects") {
        EntityTypes.CAT.state(properties(AgeableProperty(baby = false))).eyeHeight shouldBe 0.48
        EntityTypes.CAT.state(properties(AgeableProperty(baby = true))).eyeHeight shouldBe 0.28
    }

    test("a manual row is found for a pose the generated rows do not cover") {
        EntityTypes.PLAYER.state(properties(PoseProperty(EntityPose.SITTING))).height shouldBe 1.3
    }
})
