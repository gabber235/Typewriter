// The game pool: one process per run that owns Paper and the client and leases the player to the
// requirements every test JVM submits.
plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
}

dependencies {
    implementation(project(":playtest-wire"))
    implementation(project(":playtest-launch"))
    implementation(project(":protocol"))
    implementation(libs.kotlin.serialize.json)
    // Reads the JaCoCo counts each Paper hands over into the lines every attempt ran.
    implementation(libs.jacoco.core)
    testFixturesImplementation(libs.jacoco.core)
    testFixturesImplementation(project(":protocol"))
}
