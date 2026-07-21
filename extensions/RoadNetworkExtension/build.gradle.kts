repositories {}
dependencies {
    api("com.github.bsommerfeld.pathetic-bukkit:core:5.5.2")
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "RoadNetwork"
        shortDescription = "Natural Pathfinding for NPCs and Players"
        description = """
            |The road network is a way to create natural paths in the world. 
            |It can be used by NPCs to navigate to certain locations, or by players to know how to get somewhere.
            """.trimMargin()

        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper()
    }
}
