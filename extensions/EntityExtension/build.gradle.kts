repositories {}
dependencies {
    compileOnly(project(":RoadNetworkExtension"))
    compileOnly(project(":QuestExtension"))
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
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        dependencies {
            dependency("typewritermc", "RoadNetwork")
            dependency("typewritermc", "Quest")
        }

        paper()
    }
}