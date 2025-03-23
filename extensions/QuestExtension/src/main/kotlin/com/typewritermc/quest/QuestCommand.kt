package com.typewritermc.quest

import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.TypewriterCommand
import com.typewritermc.engine.paper.command.dsl.*
import com.typewritermc.engine.paper.utils.msg

@TypewriterCommand
fun CommandTree.questCommand() = literal("quest") {
    withPermission("typewriter.quest")
    literal("track") {
        withPermission("typewriter.quest.track")
        entry<QuestEntry>("quest") { quest ->
            executePlayerOrTarget { target ->
                target.trackQuest(quest().ref())
                sender.msg("You are now tracking <blue>${quest().display(target)}</blue>.")
            }
        }
    }

    literal("untrack") {
        withPermission("typewriter.quest.untrack")
        executePlayerOrTarget { target ->
            target.unTrackQuest()
            sender.msg("You are no longer tracking any quests.")
        }
    }
}