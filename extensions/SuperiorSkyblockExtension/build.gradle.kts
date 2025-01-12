import com.typewritermc.loader.ExtensionFlag

repositories {
    maven("https://repo.bg-software.com/repository/api/")
}

dependencies {
    compileOnly("com.bgsoftware:SuperiorSkyblockAPI:1.11.1")
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
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper {
            dependency("SuperiorSkyblock2")
        }
    }
}