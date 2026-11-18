// What the game's processes share about launching each other: each JVM's share of the machine's
// memory, the files a running part and the pool leave for others to find, and the pool process itself.
// It uses the standard library alone, as build-logic compiles this folder too: the Gradle service that
// owns the pool starts and stops it with the same code the unit tests here prove.
plugins {
    id("com.typewritermc.basic-conventions")
    `java-test-fixtures`
}
