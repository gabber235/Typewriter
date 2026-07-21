repositories {}
dependencies {
    compileOnly(project(":RoadNetworkExtension"))
    compileOnly(project(":QuestExtension"))

    val engineVersion = rootProject.extra["typewriterEngineVersion"] as String
    val kotestVersion = "6.1.11"
    testImplementation(project(":RoadNetworkExtension"))
    testImplementation("io.kotest:kotest-runner-junit5:$kotestVersion")
    testImplementation("io.kotest:kotest-assertions-core:$kotestVersion")
    testImplementation("com.typewritermc:engine-paper:$engineVersion")
    testImplementation("io.papermc.paper:paper-api:1.21.11-R0.1-SNAPSHOT")
}

tasks.test {
    useJUnitPlatform()
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Entity"
        shortDescription = "Create custom entities."
        description = """
            |The Entity Extension contains all the essential entries working with entities.
            |It allows you to create dynamic entities such as NPC's or Holograms.
            |
            |In most cases, it should be installed with Typewriter.
            |If you haven't installed Typewriter or the extension yet,
            |please follow the [Installation Guide](https://docs.typewritermc.com/docs/getting-started/installation)
            |first.
        """.trimMargin()
        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        dependencies {
            dependency("typewritermc", "RoadNetwork")
            dependency("typewritermc", "Quest")
        }

        paper()
    }
}