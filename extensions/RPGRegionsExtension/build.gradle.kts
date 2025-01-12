import com.typewritermc.loader.ExtensionFlag

repositories {
    maven("https://repo.convallyria.com/releases")
}

dependencies {
    compileOnly("net.islandearth.rpgregions:api:1.4.4") // 1.4.4
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "RPGRegions"
        shortDescription = "Integrate RPGRegions with Typewriter."
        description = """
            |The RPGRegions Extension is an extension that makes it easy to use RPGRegions in your dialogue.
            |Create dialogues that are triggered when the player enters or leaves a region.
        """.trimMargin()
        flag(ExtensionFlag.Deprecated)
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper {
            dependency("RPGRegions")
        }
    }
}