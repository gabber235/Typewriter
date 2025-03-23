package com.typewritermc.roadnetwork

import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.TypewriterCommand
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.command.dsl.*
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentModeTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.utils.ThreadType
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.msg
import com.typewritermc.roadnetwork.content.RoadNetworkContentMode
import com.typewritermc.roadnetwork.pathfinding.InstanceSpaceCache
import org.koin.java.KoinJavaComponent

@TypewriterCommand
fun CommandTree.roadNetworkCommand() = literal("roadNetwork") {
    withPermission("typewriter.roadNetwork")
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

    literal("info") {
        withPermission("typewriter.roadNetwork.info")
        entry<RoadNetworkEntry>("network") { entry ->
            executePlayerOrTarget { target ->
                val networkManager = KoinJavaComponent.get<RoadNetworkManager>(RoadNetworkManager::class.java)
                target.sendActionBar("Loading network...".asMini())
                ThreadType.DISPATCHERS_ASYNC.launch {
                    val network = networkManager.getNetwork(entry().ref())
                    target.sendMessage(
                        """
                        |<gray><st>${" ".repeat(60)}</st>
                        |
                        |<red><b>Road Network Info</b>: <white>${entry().name}
                        |
                        |  <gray> - <blue>Nodes: <white>${network.nodes.size}
                        |  <gray> - <green>Edges: <white>${network.edges.size}
                        |  <gray> - <dark_gray>Negative Nodes: <white>${network.negativeNodes.size}
                        |  <gray> - <gold>Modifications: <white>${network.modifications.size}
                        |  
                        |<gray><st>${" ".repeat(60)}</st>
                    """.trimMargin().asMini()
                    )
                }
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