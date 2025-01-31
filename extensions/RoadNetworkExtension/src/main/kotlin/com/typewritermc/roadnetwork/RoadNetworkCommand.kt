package com.typewritermc.roadnetwork

import com.typewritermc.core.extension.annotations.TypewriterCommand
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.command.dsl.*
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentModeTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.utils.msg
import com.typewritermc.roadnetwork.content.RoadNetworkContentMode
import com.typewritermc.roadnetwork.pathfinding.InstanceSpaceCache
import org.koin.java.KoinJavaComponent

@TypewriterCommand
fun CommandTree.roadNetworkCommand() = literal("roadNetwork") {
    literal("edit") {
        withPermission("typewriter.roadNetwork.edit")
        entry<RoadNetworkEntry>("network") { network ->
            executePlayerOrTarget { target ->
                val data = mapOf("entryId" to network().id)
                val context = ContentContext(data)
                ContentModeTrigger(
                    context,
                    RoadNetworkContentMode(context, target)
                ).triggerFor(target, context())
            }
        }
    }

    literal("clearCache") {
        withPermission("typewriter.roadNetwork.clearCache")
        executes {
            KoinJavaComponent.get<InstanceSpaceCache>(InstanceSpaceCache::class.java).clear()
            sender.msg("Cleared the instance space cache")
        }
    }
}