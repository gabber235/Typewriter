package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.protocol.entity.data.EntityData
import com.github.retrooper.packetevents.protocol.entity.data.EntityDataType
import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import net.kyori.adventure.text.Component
import org.bukkit.entity.Pose
import java.util.Optional

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

            metadata.rewriteEntityFlags(setMask = EntityFlag.GLOWING) shouldBe true

            flagsOf(metadata) shouldBe (EntityFlag.SNEAKING or EntityFlag.GLOWING)
        }

        test("clears the requested mask") {
            val metadata = listOf(flagsEntry(EntityFlag.GLOWING or EntityFlag.SPRINTING))

            metadata.rewriteEntityFlags(setMask = 0, clearMask = EntityFlag.GLOWING) shouldBe true

            flagsOf(metadata) shouldBe EntityFlag.SPRINTING
        }

        test("setting an already present flag keeps the value stable") {
            val metadata = listOf(flagsEntry(EntityFlag.GLOWING))

            metadata.rewriteEntityFlags(setMask = EntityFlag.GLOWING) shouldBe true

            flagsOf(metadata) shouldBe EntityFlag.GLOWING
        }

        test("does nothing when the packet has no flags byte") {
            val metadata = listOf(poseEntry(EntityPose.STANDING))

            metadata.rewriteEntityFlags(setMask = EntityFlag.GLOWING) shouldBe false
        }

        test("ignores non byte entries at the flags index") {
            val metadata = listOf(
                EntityData(FLAGS_METADATA_INDEX, mockk<EntityDataType<Int>>(), 5),
            )

            metadata.rewriteEntityFlags(setMask = EntityFlag.GLOWING) shouldBe false
        }

        test("leaves other metadata entries untouched") {
            val metadata = listOf(poseEntry(EntityPose.CROUCHING), flagsEntry(0))

            metadata.rewriteEntityFlags(setMask = EntityFlag.INVISIBLE) shouldBe true

            metadata[0].value shouldBe EntityPose.CROUCHING
            flagsOf(metadata) shouldBe EntityFlag.INVISIBLE
        }

        test("the full flag byte 0xFF survives a round trip") {
            val metadata = listOf(flagsEntry(0xFF))

            metadata.rewriteEntityFlags(setMask = 0, clearMask = EntityFlag.INVISIBLE) shouldBe true

            flagsOf(metadata) and 0xFF shouldBe (0xFF and EntityFlag.INVISIBLE.inv())
        }
    }

    context("rewriteEntityPose") {
        test("replaces an existing pose") {
            val metadata = listOf(poseEntry(EntityPose.STANDING))

            metadata.rewriteEntityPose(EntityPose.SLEEPING) shouldBe true

            metadata[0].value shouldBe EntityPose.SLEEPING
        }

        test("does nothing when the packet has no pose") {
            val metadata = listOf(flagsEntry(0))

            metadata.rewriteEntityPose(EntityPose.SLEEPING) shouldBe false
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
            listOf(flagsEntry(EntityFlag.ON_FIRE or EntityFlag.GLOWING)).readEntityFlags() shouldBe
                    (EntityFlag.ON_FIRE or EntityFlag.GLOWING)
        }

        test("readEntityFlags gives nothing when the packet carries no flags") {
            listOf(poseEntry(EntityPose.STANDING)).readEntityFlags().shouldBeNull()
            emptyList<EntityData<*>>().readEntityFlags().shouldBeNull()
        }
    }
    context("rewriteCustomName") {
        fun nameEntry(name: Component?): EntityData<*> =
            EntityData(
                CUSTOM_NAME_METADATA_INDEX,
                mockk<EntityDataType<Optional<Component>>>(),
                Optional.ofNullable(name),
            )

        fun visibleEntry(visible: Boolean): EntityData<*> =
            EntityData(CUSTOM_NAME_VISIBLE_METADATA_INDEX, mockk<EntityDataType<Boolean>>(), visible)

        test("replaces a name the packet already carries") {
            val metadata = mutableListOf(nameEntry(Component.text("Old")), visibleEntry(true))

            metadata.rewriteCustomName(Component.text("New"))

            metadata.readCustomName()?.orElse(null) shouldBe Component.text("New")
            metadata.readCustomNameVisible() shouldBe true
        }

        test("clearing the name hides it") {
            val metadata = mutableListOf(nameEntry(Component.text("Guard")), visibleEntry(true))

            metadata.rewriteCustomName(null)

            metadata.readCustomName()?.orElse(null).shouldBeNull()
            metadata.readCustomNameVisible() shouldBe false
        }

        test("reads nothing when the packet carries no custom name") {
            listOf(flagsEntry(0)).readCustomName().shouldBeNull()
            listOf(flagsEntry(0)).readCustomNameVisible().shouldBeNull()
        }

        test("ignores entries of the wrong type at the custom name indices") {
            val metadata = mutableListOf<EntityData<*>>(
                EntityData(CUSTOM_NAME_METADATA_INDEX, mockk<EntityDataType<Int>>(), 5),
                EntityData(CUSTOM_NAME_VISIBLE_METADATA_INDEX, mockk<EntityDataType<Int>>(), 5),
            )

            metadata.readCustomName().shouldBeNull()
            metadata.readCustomNameVisible().shouldBeNull()
        }
    }
})
