// The one wire between the test JVM, the pool, the Paper plugin and the client mod: the framing of the
// messages `skir-src/harness/v1/wire.skir` declares, the payloads Paper and the client send each other
// on the game connection, and what the parts share about launching each other. It targets the test
// JVM's Java, the oldest of the four.
plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
}

dependencies {
    api(project(":protocol"))
}
