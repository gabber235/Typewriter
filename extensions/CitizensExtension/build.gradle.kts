import com.typewritermc.loader.ExtensionFlag

repositories {
    maven("https://repo.citizensnpcs.co/")
}

dependencies {
    // External dependencies
    compileOnly("net.citizensnpcs:citizens-main:2.0.41-SNAPSHOT") {
        exclude(group = "*", module = "*")
    }
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Citizens"
        shortDescription = "Create custom interactions with Citizens NPCs."
        description = """
            |The Citizens extension allows you to create custom interactions with Citizens NPCs.
            |Letting you to create dialogues, actions, and more when interacting with NPCs.
        """.trimMargin()
        flag(ExtensionFlag.Unsupported)
        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        paper {
            dependency("Citizens")
        }
    }
}
