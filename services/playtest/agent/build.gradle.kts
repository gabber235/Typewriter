// The Java agent that lets the game pool decide when stock Paper's main loop runs a tick.
plugins {
    java
}

java {
    toolchain.languageVersion.set(JavaLanguageVersion.of(25))
}

tasks.jar {
    manifest { attributes("Premain-Class" to "com.typewritermc.playtest.agent.StepAgent") }
}
