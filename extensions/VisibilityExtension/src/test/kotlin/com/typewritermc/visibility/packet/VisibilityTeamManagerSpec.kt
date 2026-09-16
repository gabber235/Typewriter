package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import java.util.UUID

private fun pair(
    entityId: Int,
    targetName: String,
    vararg contributions: TeamContribution,
    realTeam: RealTeamInfo? = null,
    realName: String = targetName,
) = PairTeamInput(entityId, targetName, contributions.toList(), realTeam, realName)

private fun compose(
    viewerName: String,
    pairs: List<PairTeamInput>,
    viewerTeam: RealTeamInfo? = null,
) = composeTeams(viewerName, viewerTeam, pairs)

private fun teamInfo(
    color: NamedTextColor? = null,
    prefix: Component = Component.empty(),
    suffix: Component = Component.empty(),
    nameTagVisibility: WrapperPlayServerTeams.NameTagVisibility = WrapperPlayServerTeams.NameTagVisibility.ALWAYS,
    collisionRule: WrapperPlayServerTeams.CollisionRule = WrapperPlayServerTeams.CollisionRule.ALWAYS,
) = RealTeamInfo(color, prefix, suffix, nameTagVisibility, collisionRule)

class VisibilityTeamManagerSpec : FunSpec({

    test("a viewer without pairs needs no teams") {
        compose("Viewer", emptyList()) shouldBe emptyList()
    }

    test("glow gives the pair its own team with the color") {
        val teams = compose("Viewer", listOf(pair(1, "Target", TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED))))

        teams.size shouldBe 1
        teams[0].name shouldBe visibilityTeamName("p", 1)
        teams[0].color shouldBe NamedTextColor.RED
        teams[0].nameTagVisibility shouldBe WrapperPlayServerTeams.NameTagVisibility.ALWAYS
        teams[0].option shouldBe WrapperPlayServerTeams.OptionData.NONE
        teams[0].members shouldContainExactly listOf("Target")
    }

    test("a name effect's prefix and suffix win over the target's real team") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(
                    1,
                    "Target",
                    TeamContribution(
                        TeamContributionKind.NAME,
                        prefix = Component.text("[Spy] "),
                        suffix = Component.text(" !"),
                    ),
                    realTeam = teamInfo(prefix = Component.text("[Admin] "), suffix = Component.text(" *")),
                )
            ),
        )

        teams[0].prefix shouldBe Component.text("[Spy] ")
        teams[0].suffix shouldBe Component.text(" !")
    }

    test("a name effect that sets only a prefix leaves the real suffix alone") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(
                    1,
                    "Target",
                    TeamContribution(TeamContributionKind.NAME, prefix = Component.text("[Spy] ")),
                    realTeam = teamInfo(prefix = Component.text("[Admin] "), suffix = Component.text(" *")),
                )
            ),
        )

        teams[0].prefix shouldBe Component.text("[Spy] ")
        teams[0].suffix shouldBe Component.text(" *")
    }

    /**
     * A client scoreboard entry is keyed by the name the client displays, so a renamed target has to
     * be in the team under the name they were renamed to, never the one the server knows.
     */
    test("the team is keyed by the name the client knows, not the server's") {
        val teams = compose(
            "Viewer",
            listOf(pair(1, "Ghost_7", TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED))),
        )

        teams[0].members shouldContainExactly listOf("Ghost_7")
    }

    /**
     * Renaming a target removes them from every team their client knows, since none of those list the
     * new name. The pair therefore needs a team of its own even with nothing to change, purely to
     * carry the real team's appearance over to the new name.
     */
    test("a renamed pair with nothing to change still gets its real team copied over") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(
                    1,
                    "Ghost_7",
                    realTeam = teamInfo(
                        color = NamedTextColor.GOLD,
                        prefix = Component.text("[Admin] "),
                        nameTagVisibility = WrapperPlayServerTeams.NameTagVisibility.NEVER,
                    ),
                )
            ),
        )

        teams.size shouldBe 1
        teams[0].members shouldContainExactly listOf("Ghost_7")
        teams[0].color shouldBe NamedTextColor.GOLD
        teams[0].prefix shouldBe Component.text("[Admin] ")
        teams[0].nameTagVisibility shouldBe WrapperPlayServerTeams.NameTagVisibility.NEVER
    }

    test("two targets the viewer reads the same name on are reported") {
        val pairs = listOf(
            pair(1, "Ghost_7", TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED)),
            pair(2, "Ghost_7", TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.BLUE)),
        )

        duplicateTargetName(pairs) shouldBe "Ghost_7"
    }

    test("targets with names of their own are not reported") {
        val pairs = listOf(pair(1, "Ghost_7"), pair(2, "Ghost_8"), pair(3, "Target"))

        duplicateTargetName(pairs) shouldBe null
    }

    test("a viewer nobody has read the teams of yet is due right away") {
        val viewer = UUID.randomUUID()

        // A never refreshed viewer counts as further back than the cooldown, so a one off rank change
        // reaches the client on the next tick rather than waiting out a window.
        dueForRealTeamRefresh(listOf(viewer), tick = 1) { -REAL_TEAM_REFRESH_COOLDOWN_TICKS } shouldContainExactly
                listOf(viewer)
    }

    test("a viewer read on this very tick waits") {
        val viewer = UUID.randomUUID()

        dueForRealTeamRefresh(listOf(viewer), tick = 40) { 40 } shouldContainExactly emptyList()
    }

    test("a viewer becomes due again exactly one cooldown later, never sooner") {
        val viewer = UUID.randomUUID()
        val lastRefresh = 40L

        val justShort = lastRefresh + REAL_TEAM_REFRESH_COOLDOWN_TICKS - 1
        dueForRealTeamRefresh(listOf(viewer), justShort) { lastRefresh } shouldContainExactly emptyList()
        dueForRealTeamRefresh(listOf(viewer), justShort + 1) { lastRefresh } shouldContainExactly listOf(viewer)
    }

    test("only the viewers that are due come back, so the rest keep their request") {
        val due = UUID.randomUUID()
        val cooling = UUID.randomUUID()
        val lastRefresh = mapOf(due to 0L, cooling to 40L)

        dueForRealTeamRefresh(listOf(due, cooling), tick = 41) { lastRefresh.getValue(it) } shouldContainExactly
                listOf(due)
    }

    test("a disguise under the name of a player on the server is reported") {
        val pairs = listOf(pair(1, "Alice", realName = "Bob"), pair(2, "Charlie"))

        stolenTargetName(pairs) { it == "Alice" }?.realName shouldBe "Bob"
    }

    test("a disguise under a name nobody goes by is left alone") {
        val pairs = listOf(pair(1, "Alice", realName = "Bob"))

        stolenTargetName(pairs) { it == "Dave" } shouldBe null
    }

    test("a target under their own name is never reported, however common it is") {
        val pairs = listOf(pair(1, "Bob"), pair(2, "Charlie"))

        // The predicate accepts every name, so only the disguise filter can keep this null.
        stolenTargetName(pairs) { true } shouldBe null
    }

    test("the viewer's own name counts as stolen, since it decides the ghost team") {
        val pairs = listOf(pair(1, "Viewer", realName = "Bob"))

        stolenTargetName(pairs) { it == "Viewer" }?.entityId shouldBe 1
    }

    test("hidden nametag forces the name tag off") {
        val teams = compose("Viewer", listOf(pair(1, "Target", TeamContribution(TeamContributionKind.NAMETAG_HIDDEN, hidesNametag = true))))

        teams[0].nameTagVisibility shouldBe WrapperPlayServerTeams.NameTagVisibility.NEVER
    }

    test("ghost puts the viewer and the target in the shared ghost team") {
        val teams = compose("Viewer", listOf(pair(1, "Target", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true))))

        teams.size shouldBe 1
        teams[0].name shouldBe GHOST_TEAM_NAME
        teams[0].option shouldBe WrapperPlayServerTeams.OptionData.FRIENDLY_CAN_SEE_INVISIBLE
        teams[0].members shouldContainExactly listOf("Target", "Viewer")
    }

    test("every ghost target of a viewer shares one team so they all stay translucent") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(2, "Second", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
                pair(1, "First", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
            ),
        )

        teams.size shouldBe 1
        teams[0].name shouldBe GHOST_TEAM_NAME
        teams[0].members shouldContainExactlyInAnyOrder listOf("First", "Second", "Viewer")
    }

    test("the shared ghost team takes the color of the lowest entity id") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(
                    2,
                    "Second",
                    TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                    TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.BLUE),
                ),
                pair(
                    1,
                    "First",
                    TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                    TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED),
                ),
            ),
        )

        teams[0].color shouldBe NamedTextColor.RED
    }

    test("ghost pairs that disagree are reported as a conflict") {
        val agreeing = listOf(
            pair(1, "First", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
            pair(2, "Second", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
        )
        val disagreeing = listOf(
            pair(
                1,
                "First",
                TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED),
            ),
            pair(
                2,
                "Second",
                TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.BLUE),
            ),
        )

        hasGhostConflict(agreeing) shouldBe false
        hasGhostConflict(disagreeing) shouldBe true
    }

    test("a pair without a ghost keeps its own team next to the ghost team") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(1, "Ghost", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
                pair(2, "Glowing", TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.GREEN)),
            ),
        )

        teams.map { it.name } shouldContainExactlyInAnyOrder listOf(GHOST_TEAM_NAME, visibilityTeamName("p", 2))
        val glowing = teams.first { it.name == visibilityTeamName("p", 2) }
        glowing.color shouldBe NamedTextColor.GREEN
        glowing.option shouldBe WrapperPlayServerTeams.OptionData.NONE
        glowing.members shouldContainExactly listOf("Glowing")
    }

    test("a self effect never puts the viewer in a second team next to the ghost team") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(1, "Ghost", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
                pair(7, "Viewer", TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED)),
            ),
        )

        teams.count { "Viewer" in it.members } shouldBe 1
        teams.map { it.name } shouldContainExactly listOf(GHOST_TEAM_NAME)
        teams[0].members shouldContainExactlyInAnyOrder listOf("Ghost", "Viewer")
    }

    test("the ghost team takes the viewer's own color and collision rule") {
        val teams = compose(
            "Viewer",
            listOf(pair(1, "Ghost", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true))),
            viewerTeam = teamInfo(
                color = NamedTextColor.GOLD,
                collisionRule = WrapperPlayServerTeams.CollisionRule.NEVER,
            ),
        )

        teams[0].color shouldBe NamedTextColor.GOLD
        teams[0].collisionRule shouldBe WrapperPlayServerTeams.CollisionRule.NEVER
    }

    test("a ghost color still wins over the viewer's own team color") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(
                    1,
                    "Ghost",
                    TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                    TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED),
                )
            ),
            viewerTeam = teamInfo(color = NamedTextColor.GOLD),
        )

        teams[0].color shouldBe NamedTextColor.RED
    }

    test("one ghost with a color and one without is a conflict") {
        val pairs = listOf(
            pair(1, "First", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
            pair(
                2,
                "Second",
                TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED),
            ),
        )

        hasGhostConflict(pairs) shouldBe true
    }

    test("ghost on a self pair does not duplicate the member") {
        val teams = compose("Target", listOf(pair(1, "Target", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true))))

        teams[0].members shouldContainExactly listOf("Target")
    }

    test("glow ghost and hidden nametag on one pair merge into the ghost team") {
        val teams = compose(
            "Viewer",
            listOf(
                pair(
                    1,
                    "Target",
                    TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.AQUA),
                    TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                    TeamContribution(TeamContributionKind.NAMETAG_HIDDEN, hidesNametag = true),
                ),
            ),
        )

        teams.size shouldBe 1
        teams[0].color shouldBe NamedTextColor.AQUA
        teams[0].nameTagVisibility shouldBe WrapperPlayServerTeams.NameTagVisibility.NEVER
        teams[0].option shouldBe WrapperPlayServerTeams.OptionData.FRIENDLY_CAN_SEE_INVISIBLE
        teams[0].members shouldContainExactly listOf("Target", "Viewer")
    }

    test("a pair team keeps the formatting of the target's real team") {
        val realTeam = RealTeamInfo(
            color = NamedTextColor.GOLD,
            prefix = Component.text("[Admin] "),
            suffix = Component.text(" *"),
            nameTagVisibility = WrapperPlayServerTeams.NameTagVisibility.ALWAYS,
            collisionRule = WrapperPlayServerTeams.CollisionRule.NEVER,
        )
        val teams = compose(
            "Viewer",
            listOf(pair(1, "Target", TeamContribution(TeamContributionKind.NAMETAG_HIDDEN, hidesNametag = true), realTeam = realTeam)),
        )

        teams[0].color shouldBe NamedTextColor.GOLD
        teams[0].prefix shouldBe Component.text("[Admin] ")
        teams[0].suffix shouldBe Component.text(" *")
        teams[0].collisionRule shouldBe WrapperPlayServerTeams.CollisionRule.NEVER
        teams[0].nameTagVisibility shouldBe WrapperPlayServerTeams.NameTagVisibility.NEVER
    }

    test("a glow color overrides the real team color") {
        val realTeam = RealTeamInfo(
            color = NamedTextColor.GOLD,
            prefix = Component.empty(),
            suffix = Component.empty(),
            nameTagVisibility = WrapperPlayServerTeams.NameTagVisibility.ALWAYS,
            collisionRule = WrapperPlayServerTeams.CollisionRule.ALWAYS,
        )
        val teams = compose(
            "Viewer",
            listOf(pair(1, "Target", TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED), realTeam = realTeam)),
        )

        teams[0].color shouldBe NamedTextColor.RED
    }

    test("ghost pairs that disagree about the nametag are reported as a conflict") {
        val pairs = listOf(
            pair(
                1, "First",
                TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true),
                TeamContribution(TeamContributionKind.NAMETAG_HIDDEN, hidesNametag = true),
            ),
            pair(2, "Second", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true)),
        )

        hasGhostConflict(pairs) shouldBe true
    }

    test("the ghost team falls back to the viewer's own nametag setting") {
        val teams = compose(
            "Viewer",
            listOf(pair(1, "Target", TeamContribution(TeamContributionKind.GHOST, friendlyInvisible = true))),
            viewerTeam = teamInfo(nameTagVisibility = WrapperPlayServerTeams.NameTagVisibility.HIDE_FOR_OTHER_TEAMS),
        )

        teams[0].nameTagVisibility shouldBe WrapperPlayServerTeams.NameTagVisibility.HIDE_FOR_OTHER_TEAMS
    }

    test("a team packet that names nobody we hold goes out untouched") {
        editTeamPacket(
            "rank_admin",
            WrapperPlayServerTeams.TeamMode.REMOVE_ENTITIES,
            listOf("Someone"),
            setOf("Target"),
        ) shouldBe TeamPacketEdit.Untouched
    }

    test("removing every name we hold from a real team is cancelled instead of sent") {
        editTeamPacket(
            "collideRule_1234",
            WrapperPlayServerTeams.TeamMode.REMOVE_ENTITIES,
            listOf("Target"),
            setOf("Target", "Viewer"),
        ) shouldBe TeamPacketEdit.Cancel
    }

    test("a real team keeps the names we do not hold") {
        editTeamPacket(
            "rank_admin",
            WrapperPlayServerTeams.TeamMode.ADD_ENTITIES,
            listOf("Target", "Someone"),
            setOf("Target"),
        ) shouldBe TeamPacketEdit.KeepMembers(listOf("Someone"))
    }

    test("a real team create still goes out once every name we hold is stripped") {
        editTeamPacket(
            "rank_admin",
            WrapperPlayServerTeams.TeamMode.CREATE,
            listOf("Target"),
            setOf("Target"),
        ) shouldBe TeamPacketEdit.KeepMembers(emptyList())
    }

    test("our own teams are never filtered") {
        editTeamPacket(
            GHOST_TEAM_NAME,
            WrapperPlayServerTeams.TeamMode.ADD_ENTITIES,
            listOf("Target", "Viewer"),
            setOf("Target", "Viewer"),
        ) shouldBe TeamPacketEdit.Untouched

        editTeamPacket(
            visibilityTeamName("p", 7),
            WrapperPlayServerTeams.TeamMode.CREATE,
            listOf("Target"),
            setOf("Target"),
        ) shouldBe TeamPacketEdit.Untouched
    }

    test("a team update carries no members and is left alone") {
        editTeamPacket(
            "rank_admin",
            WrapperPlayServerTeams.TeamMode.UPDATE,
            emptyList(),
            setOf("Target"),
        ) shouldBe TeamPacketEdit.Untouched
    }

    test("a viewer holding nothing pays for no filtering at all") {
        editTeamPacket(
            "rank_admin",
            WrapperPlayServerTeams.TeamMode.REMOVE_ENTITIES,
            listOf("Target"),
            emptySet(),
        ) shouldBe TeamPacketEdit.Untouched
    }
})
