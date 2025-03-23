package com.typewritermc.engine.paper.entry.temporal

import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.command.dsl.CommandTree
import com.typewritermc.engine.paper.command.dsl.executePlayerOrTarget
import com.typewritermc.engine.paper.command.dsl.page
import com.typewritermc.engine.paper.command.dsl.withPermission
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.triggerFor

fun CommandTree.temporalCommand() = literal("cinematic") {
    withPermission("typewriter.cinematic")
    literal("start") {
        withPermission("typewriter.cinematic.start")
        page("cinematic", PageType.CINEMATIC) { page ->
            executePlayerOrTarget { target ->
                TemporalStartTrigger(page().id, emptyList()).triggerFor(target, context())
            }
        }
    }

    literal("stop") {
        withPermission("typewriter.cinematic.stop")
        executePlayerOrTarget { target ->
            InteractionEndTrigger.triggerFor(target, context())
        }
    }
}
