package com.typewritermc.visibility.packet

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import java.util.UUID

class VisibilityPacketBridgeSpec : FunSpec({

    val hook = object : EntityPacketHook {}
    val otherHook = object : EntityPacketHook {}
    val profileHook = object : ProfilePacketHook {
        override fun onPlayerInfo(
            actions: java.util.EnumSet<com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoUpdate.Action>,
            entry: com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoUpdate.PlayerInfo,
        ) = Unit
    }

    test("entity hooks can be added and removed") {
        val bridge = VisibilityPacketBridge()
        val viewer = UUID.randomUUID()

        bridge.addEntityHook(viewer, 42, hook)
        bridge.entityHookCount(viewer, 42) shouldBe 1

        bridge.removeEntityHook(viewer, 42, hook)
        bridge.entityHookCount(viewer, 42) shouldBe 0
    }

    test("removing the last hook cleans up the viewer entry entirely") {
        val bridge = VisibilityPacketBridge()
        val viewer = UUID.randomUUID()

        bridge.addEntityHook(viewer, 42, hook)
        bridge.addEntityHook(viewer, 43, otherHook)
        bridge.removeEntityHook(viewer, 42, hook)
        bridge.hasHooksFor(viewer) shouldBe true

        bridge.removeEntityHook(viewer, 43, otherHook)
        bridge.hasHooksFor(viewer) shouldBe false
    }

    test("multiple hooks can share the same viewer and entity") {
        val bridge = VisibilityPacketBridge()
        val viewer = UUID.randomUUID()

        bridge.addEntityHook(viewer, 42, hook)
        bridge.addEntityHook(viewer, 42, otherHook)
        bridge.entityHookCount(viewer, 42) shouldBe 2

        bridge.removeEntityHook(viewer, 42, hook)
        bridge.entityHookCount(viewer, 42) shouldBe 1
    }

    test("removing a hook that was never added is a no op") {
        val bridge = VisibilityPacketBridge()
        val viewer = UUID.randomUUID()

        bridge.removeEntityHook(viewer, 42, hook)
        bridge.hasHooksFor(viewer) shouldBe false
    }

    test("forgetting a viewer drops every hook they had") {
        val bridge = VisibilityPacketBridge()
        val viewer = UUID.randomUUID()
        val profile = UUID.randomUUID()

        bridge.addEntityHook(viewer, 42, hook)
        bridge.addEntityHook(viewer, 43, otherHook)
        bridge.addProfileHook(viewer, profile, profileHook)

        bridge.forget(viewer)

        bridge.hasHooksFor(viewer) shouldBe false
        bridge.entityHookCount(viewer, 42) shouldBe 0
        bridge.profileHookCount(viewer, profile) shouldBe 0
    }

    test("profile hooks are tracked separately from entity hooks") {
        val bridge = VisibilityPacketBridge()
        val viewer = UUID.randomUUID()
        val profile = UUID.randomUUID()

        bridge.addProfileHook(viewer, profile, profileHook)
        bridge.profileHookCount(viewer, profile) shouldBe 1
        bridge.entityHookCount(viewer, 42) shouldBe 0
        bridge.hasHooksFor(viewer) shouldBe true

        bridge.removeProfileHook(viewer, profile, profileHook)
        bridge.hasHooksFor(viewer) shouldBe false
    }
})
