package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.protocol.entity.data.EntityData
import com.github.retrooper.packetevents.protocol.entity.data.EntityDataType
import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.entity.Pose

class MetadataPacketsSpec : FunSpec({

    fun flagsEntry(flags: Int): EntityData<*> =
        EntityData(FLAGS_METADATA_INDEX, mockk<EntityDataType<Byte>>(), flags.toByte())

    fun poseEntry(pose: EntityPose): EntityData<*> =
        EntityData(POSE_METADATA_INDEX, mockk<EntityDataType<EntityPose>>(), pose)

    fun flagsOf(metadata: List<EntityData<*>>): Int =
        (metadata.first { it.index == FLAGS_METADATA_INDEX }.value as Byte).toInt()

    context("rewriteEntityFlags") {
        test("sets the mask on an existing flags byte") {
            val metadata = listOf(flagsEntry(EntityFlag.SNEAKING))

            rewriteEntityFlags(metadata, setMask = EntityFlag.GLOWING) shouldBe true

            flagsOf(metadata) shouldBe (EntityFlag.SNEAKING or EntityFlag.GLOWING)
        }

        test("clears the requested mask") {
            val metadata = listOf(flagsEntry(EntityFlag.GLOWING or EntityFlag.SPRINTING))

            rewriteEntityFlags(metadata, setMask = 0, clearMask = EntityFlag.GLOWING) shouldBe true

            flagsOf(metadata) shouldBe EntityFlag.SPRINTING
        }

        test("setting an already present flag keeps the value stable") {
            val metadata = listOf(flagsEntry(EntityFlag.GLOWING))

            rewriteEntityFlags(metadata, setMask = EntityFlag.GLOWING) shouldBe true

            flagsOf(metadata) shouldBe EntityFlag.GLOWING
        }

        test("does nothing when the packet has no flags byte") {
            val metadata = listOf(poseEntry(EntityPose.STANDING))

            rewriteEntityFlags(metadata, setMask = EntityFlag.GLOWING) shouldBe false
        }

        test("ignores non byte entries at the flags index") {
            val metadata = listOf(
                EntityData(FLAGS_METADATA_INDEX, mockk<EntityDataType<Int>>(), 5),
            )

            rewriteEntityFlags(metadata, setMask = EntityFlag.GLOWING) shouldBe false
        }

        test("leaves other metadata entries untouched") {
            val metadata = listOf(poseEntry(EntityPose.CROUCHING), flagsEntry(0))

            rewriteEntityFlags(metadata, setMask = EntityFlag.INVISIBLE) shouldBe true

            metadata[0].value shouldBe EntityPose.CROUCHING
            flagsOf(metadata) shouldBe EntityFlag.INVISIBLE
        }

        test("the full flag byte 0xFF survives a round trip") {
            val metadata = listOf(flagsEntry(0xFF))

            rewriteEntityFlags(metadata, setMask = 0, clearMask = EntityFlag.INVISIBLE) shouldBe true

            flagsOf(metadata) and 0xFF shouldBe (0xFF and EntityFlag.INVISIBLE.inv())
        }
    }

    context("rewriteEntityPose") {
        test("replaces an existing pose") {
            val metadata = listOf(poseEntry(EntityPose.STANDING))

            rewriteEntityPose(metadata, EntityPose.SLEEPING) shouldBe true

            metadata[0].value shouldBe EntityPose.SLEEPING
        }

        test("does nothing when the packet has no pose") {
            val metadata = listOf(flagsEntry(0))

            rewriteEntityPose(metadata, EntityPose.SLEEPING) shouldBe false
        }
    }

    context("pose mapping") {
        test("sneaking maps to crouching") {
            Pose.SNEAKING.toEntityPose() shouldBe EntityPose.CROUCHING
        }

        test("matching names map directly") {
            Pose.STANDING.toEntityPose() shouldBe EntityPose.STANDING
            Pose.SWIMMING.toEntityPose() shouldBe EntityPose.SWIMMING
            Pose.SLEEPING.toEntityPose() shouldBe EntityPose.SLEEPING
            Pose.FALL_FLYING.toEntityPose() shouldBe EntityPose.FALL_FLYING
        }

        test("every bukkit pose keeps its own name, crouching aside") {
            val mismatched = Pose.entries
                .filter { it != Pose.SNEAKING }
                .filter { it.toEntityPose().name != it.name }

            mismatched shouldBe emptyList()
        }

        test("readEntityFlags gives back the byte a packet carries") {
            readEntityFlags(listOf(flagsEntry(EntityFlag.ON_FIRE or EntityFlag.GLOWING))) shouldBe
                    (EntityFlag.ON_FIRE or EntityFlag.GLOWING)
        }

        test("readEntityFlags gives nothing when the packet carries no flags") {
            readEntityFlags(listOf(poseEntry(EntityPose.STANDING))).shouldBeNull()
            readEntityFlags(emptyList()).shouldBeNull()
        }
    }
})
