// The one wire between the test JVM, the pool, the Paper plugin and the client mod. Plain Java with
// no dependencies, so the Fabric client and the Paper plugin carry it without a Kotlin runtime; it
// targets the test JVM's Java, the oldest of the four.
plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
}

dependencies {
    testImplementation(libs.kotest.property)
}
