repositories { }
dependencies {
    implementation("com.mthaler:aparser:0.4.0")
}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Basic"
        shortDescription = "For all the most basic entries"
        description = """
            The Basic Extension contains all the essential entries for any server.
            In most cases, it should be installed with Typewriter.
            If you haven't installed Typewriter or the Basic Extension,
            please follow the [Installation Guide](https://docs.typewritermc.com/docs/getting-started/installation)
            first.
        """.trimIndent()
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        paper()
    }
}