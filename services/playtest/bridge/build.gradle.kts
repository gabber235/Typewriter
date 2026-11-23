// The playtest bridge: a test only Typewriter extension that game test modules install on every game
// Paper (`gamePaper { typewriterExtensions.from(project(":playtest-bridge")) }`). Its Paper part uses the
// Playtest plugin, so it loads only on engines whose Paper runs the game verification framework.
plugins {
    id("com.typewritermc.basic-conventions")
    id("com.typewritermc.imprint")
    id("com.typewritermc.paper-api")
}

typewriter {
    extension {
        id = "typewritermc:playtest-bridge"
        version = "1.0.0"

        val playtest = plugin("Playtest") { api(project(":playtest-plugin")) }
        sourceSet("enginePaper") {
            engine(project(":engine-paper"), version = "^1")
            uses(playtest)
        }
    }
}

dependencies {
    imprintExtensionApi(project(":typewriter-api"))
    imprintEngineCore(project(":engine-core"))
}
