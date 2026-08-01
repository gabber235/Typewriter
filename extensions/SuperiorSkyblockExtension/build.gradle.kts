import com.typewritermc.loader.ExtensionFlag

repositories {
    maven("https://repo.bg-software.com/repository/api/") {
        content { includeGroupAndSubgroups("com.bgsoftware") }
    }
}

dependencies {
    compileOnly("com.bgsoftware:SuperiorSkyblockAPI:2026.1")
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "SuperiorSkyblock"
        shortDescription = "Integrate SuperiorSkyblock with Typewriter."
        description = """
            |The Superior Skyblock Extension allows you to use the Superior Skyblock plugin with TypeWriter.
            |It includes many events for you to use in your dialogue, as well as a few actions and conditions.
        """.trimMargin()
        flag(ExtensionFlag.Deprecated)
        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper {
            dependency("SuperiorSkyblock2")
        }
    }
}
