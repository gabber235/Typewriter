package com.typewritermc.realm.storage

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.net.URI
import java.nio.file.Path

val RealmDatabaseConfigurationTest by testSuite {
    test("embedded engines always enable versioning") {
        DatabaseEndpoint.Embedded.Memory().connectionString shouldBe "mem://?versioned=true"
        DatabaseEndpoint.Embedded.SurrealKv(Path.of("database/realm"), "30d").connectionString shouldBe
            "surrealkv://database/realm?versioned=true&retention=30d"
        DatabaseEndpoint.Embedded.RocksDb(Path.of("database/realm")).connectionString shouldBe
            "rocksdb://database/realm?versioned=true"
    }

    test("absolute embedded paths preserve their meaning") {
        DatabaseEndpoint.Embedded.SurrealKv(Path.of("/var/lib/realm")).connectionString shouldBe
            "surrealkv:///var/lib/realm?versioned=true"
    }

    test("embedded databases reject authentication") {
        shouldThrow<IllegalArgumentException> {
            RealmDatabaseConfiguration(
                endpoint = DatabaseEndpoint.Embedded.Memory(),
                authentication = DatabaseAuthentication.Root("root", "secret"),
                namespace = "typewriter",
                database = "realm",
                expectedVersion = "3.0.0",
            )
        }.message shouldBe "Embedded databases do not support authentication"
    }

    test("a remote URL with an unsupported scheme is rejected") {
        shouldThrow<IllegalArgumentException> { DatabaseEndpoint.Remote(URI("nats://localhost:4222")) }
            .message shouldBe "Remote database URL must use HTTP or WebSocket"
    }

    test("a remote URL without a host is rejected") {
        shouldThrow<IllegalArgumentException> { DatabaseEndpoint.Remote(URI("ws:localhost")) }
            .message shouldBe "Remote database URL must include a host"
    }

    test("a remote URL with embedded credentials is rejected") {
        shouldThrow<IllegalArgumentException> { DatabaseEndpoint.Remote(URI("wss://realm:secret@database.example.com")) }
            .message shouldBe "Remote database URL must not contain credentials"
    }

    test("authentication does not expose secrets") {
        DatabaseAuthentication.Root("realm", "secret").toString() shouldBe
            "Root(username=realm, password=[redacted])"
        DatabaseAuthentication.Bearer("token").toString() shouldBe "Bearer(token=[redacted])"
    }
}
