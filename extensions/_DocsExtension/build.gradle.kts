repositories {}
dependencies {}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Documentation"
        shortDescription = "Documentation for Typewriter."
        description = """
            |This extension contains the documentation for Typewriter.
            |It has examples of how to use the different parts of Typewriter.
            |It should not be used as a dependency.
            """.trimMargin()
        engineVersion = file("../../version.txt").readText().trim()
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE


        paper()
    }
}
