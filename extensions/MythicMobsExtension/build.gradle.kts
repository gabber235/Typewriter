import com.typewritermc.loader.ExtensionFlag

repositories {
    maven("https://mvn.lumine.io/repository/maven-public/")
}

dependencies {
    compileOnly("io.lumine:Mythic-Dist:5.6.1")
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "MythicMobs"
        shortDescription = "Integrate MythicMobs with Typewriter."
        description = """
            |The MythicMobs Extension allows you to create MyticMobs, and trigger Skills from Typewriter.
            |Create cool particles during cinematics or have dialgues triggered when interacting with a MythicMob.
        """.trimMargin()
        flag(ExtensionFlag.Deprecated)
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper {
            dependency("MythicMobs")
        }
    }
}