repositories {}
dependencies {
    api("com.extollit.gaming:hydrazine-path-engine:1.8.1")
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

        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper()
    }
}
