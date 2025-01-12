repositories {
    maven("https://maven.enginehub.org/repo/")
}

dependencies {
    compileOnly("com.sk89q.worldguard:worldguard-bukkit:7.0.13-SNAPSHOT") {
        exclude(group = "com.google.guava")
        exclude(group = "com.google.code.gson")
        exclude(group = "it.unimi.dsi")
    }
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "WorldGuard"
        shortDescription = "Integrate WorldGuard with Typewriter."
        description = """
            |The WorldGuard Extension allows you to create dialogue triggered by WorldGuard regions.
            |Have dialogues that only show up when a player enters or leaves a specific region.
            |Have sidebars that only show when the player is in a specific region.
        """.trimMargin()
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper {
            dependency("WorldGuard")
        }
    }
}