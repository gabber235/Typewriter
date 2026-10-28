plugins {
    base
    id("com.typewritermc.coverage-merge")
}

subprojects {
    version = "1000.0.0"
}

tasks.named("check") {
    dependsOn(subprojects.map { "${it.path}:check" })
}
