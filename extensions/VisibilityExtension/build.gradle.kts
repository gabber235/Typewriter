repositories {}

typewriter {
    namespace = "typewritermc"

    extension {
        name = "Visibility"
        shortDescription = "Change how players are displayed to other players."
        description = """
            |The Visibility extension controls how players are rendered to other players.
            |Rules select which viewers see which targets differently, and effects define what changes:
            |hide players completely, make them glow in a color, render them as translucent ghosts,
            |swap their skin, disguise them as another entity, change their size or pose,
            |hide or replace their armor, and modify their nametag.
            |Rules follow audiences, so visibility reacts to quests, facts, and any other audience logic,
            |with priorities deciding which effect wins when multiple rules apply to the same pair of players.
            """.trimMargin()

        engineVersion = rootProject.extra["typewriterEngineVersion"] as String
        channel = com.typewritermc.moduleplugin.ReleaseChannel.NONE

        paper()
    }
}
