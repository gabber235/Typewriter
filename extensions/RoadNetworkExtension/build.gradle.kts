repositories {}
dependencies {
    api("com.github.bsommerfeld.pathetic-bukkit:core:5.5.2")

    val engineVersion = rootProject.extra["typewriterEngineVersion"] as String
    val kotestVersion = "6.1.11"
    testImplementation("io.kotest:kotest-runner-junit5:$kotestVersion")
    testImplementation("io.kotest:kotest-assertions-core:$kotestVersion")
    testImplementation("io.mockk:mockk:1.14.9")
    testImplementation("com.typewritermc:engine-paper:$engineVersion")
    testImplementation("io.papermc.paper:paper-api:1.21.11-R0.1-SNAPSHOT")
    testImplementation("org.mockbukkit.mockbukkit:mockbukkit-v1.21:4.108.0")
}

tasks.test {
    useJUnitPlatform()
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
