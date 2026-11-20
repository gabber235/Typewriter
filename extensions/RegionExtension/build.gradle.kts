repositories {}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Region"
        shortDescription = "Whatever region you need, we got it."
        description = """
            |The Region extension adds spatial regions, 3D volumes you can hook into events,
            |audience filters, facts, variables, and actions. Regions can be static (anchored
            |to fixed coordinates) or dynamic (anchored to NPC/player locations, fact-driven
            |positions, or interpolated paths) using the same definition shape.
            """.trimMargin()

        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        paper()
    }
}
