package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.typewritermc.engine.paper.entry.entries.ConstVar
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.mockk
import org.bukkit.GameMode
import org.bukkit.World

class DisguiseVisibilityEffectEntrySpec : FunSpec({

    test("a toggle that is always off settles the disguise's self view") {
        DisguiseVisibilityEffectEntry(self = ConstVar(false)).selfView shouldBe SelfView.Never
    }

    test("a toggle that is always on still asks each player, who may be riding, dead or spectating") {
        DisguiseVisibilityEffectEntry(self = ConstVar(true)).selfView.shouldBeInstanceOf<SelfView.PerPlayer>()
    }

    test("a standing player sees their own disguise in every game mode but spectator") {
        listOf(GameMode.SURVIVAL, GameMode.CREATIVE, GameMode.ADVENTURE).forEach { gameMode ->
            canShowOwnDisguise(riding = false, dead = false, gameMode = gameMode) shouldBe true
        }
    }

    test("riding, being dead or spectating leaves the player's own disguise out") {
        canShowOwnDisguise(riding = true, dead = false, gameMode = GameMode.SURVIVAL) shouldBe false
        canShowOwnDisguise(riding = false, dead = true, gameMode = GameMode.SURVIVAL) shouldBe false
        canShowOwnDisguise(riding = false, dead = false, gameMode = GameMode.SPECTATOR) shouldBe false
    }

    test("a mob disguise seen by another player needs nothing from the team") {
        disguiseTeamContribution(fakePlayer = false, selfView = false).shouldBeNull()
    }

    test("a fake player starts from a team that hides its nametag and does not collide") {
        val contribution = disguiseTeamContribution(fakePlayer = true, selfView = false).shouldNotBeNull()

        contribution.hidesNametag shouldBe false
        contribution.collisionRule.shouldBeNull()
        contribution.baseTeam shouldBe FAKE_PLAYER_BASE_TEAM
    }

    test("the player's own disguise never pushes them, and a mob keeps its name visible") {
        val contribution = disguiseTeamContribution(fakePlayer = false, selfView = true).shouldNotBeNull()

        contribution.hidesNametag shouldBe false
        contribution.baseTeam.shouldBeNull()
        contribution.collisionRule shouldBe WrapperPlayServerTeams.CollisionRule.NEVER
    }

    test("a disguise is shown in the world both players share") {
        val world = mockk<World>()

        disguiseWorld(world, world, hiddenByOthers = false) shouldBe world
    }

    test("a disguise stays away from a viewer in another world") {
        disguiseWorld(mockk(), mockk(), hiddenByOthers = false).shouldBeNull()
    }

    test("a disguise stays away while another feature hides the target") {
        val world = mockk<World>()

        disguiseWorld(world, world, hiddenByOthers = true).shouldBeNull()
    }
})
