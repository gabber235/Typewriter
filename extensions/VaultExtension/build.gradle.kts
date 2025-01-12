repositories {
    exclusiveContent {
        forRepository {
            maven {
                url = uri("https://jitpack.io")
            }
        }
        filter {
            includeGroup("com.github.MilkBowl")
        }
    }
}
dependencies {
    compileOnly("com.github.MilkBowl:VaultAPI:1.7.1")
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Vault"
        shortDescription = "Integrate Vault with Typewriter."
        description = """
            |The Vault Extension is an extension that makes it easy to use Vault's economy system in your dialogue.
        """.trimMargin()
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper {
            dependency("Vault")
        }
    }
}