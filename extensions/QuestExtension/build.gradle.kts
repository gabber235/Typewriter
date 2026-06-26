repositories {}
dependencies {
    compileOnly(project(":RoadNetworkExtension"))

    val kotestVersion = "6.1.11"
    testImplementation("io.kotest:kotest-runner-junit5:$kotestVersion")
    testImplementation("io.kotest:kotest-assertions-core:$kotestVersion")
}

tasks.test {
    useJUnitPlatform()
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Quest"
        shortDescription = "Questing System in Typewriter"
        description = """
            |A questing system for Typewriter that allows players to track quests and complete them.
            |The questing system is for displaying the progress to a player.
            |
            |It is **not** necessary to use this extension for quests.
            |It is just a visual novelty.
            """.trimMargin()
        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        dependencies {
            dependency("typewritermc", "RoadNetwork")
        }

        paper()
    }
}
