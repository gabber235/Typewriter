// The game pool: one process per run that owns Paper and the client and leases the player to the
// requirements every test JVM submits.
plugins {
    id("com.typewritermc.basic-conventions")
}

dependencies {
    implementation(project(":playtest-wire"))
    implementation(project(":protocol"))
    implementation(libs.kotlin.serialize.json)
}
