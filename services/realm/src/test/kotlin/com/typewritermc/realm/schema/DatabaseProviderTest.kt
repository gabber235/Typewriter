package com.typewritermc.realm.schema

import com.typewritermc.services.libs.telemetry.testing.MockTelemetry
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import java.net.InetSocketAddress
import java.net.Socket

class DatabaseProviderTest : FunSpec({

    val tracer = MockTelemetry.createMockTracer()
    val span = MockTelemetry.createMockSpan()

    fun isExternalDbRunning(): Boolean {
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress("localhost", 8235), 500)
                true
            }
        } catch (_: Exception) {
            false
        }
    }

    fun provider(
        url: String = "",
        username: String = "",
        password: String = "",
        namespace: String = "typewriter",
        database: String = "realm",
    ) = DatabaseProvider(url, username, password, namespace, database, tracer)

    context("resolveConnectionMode") {

        test("explicit URL forces external mode") {
            val p = provider(url = "ws://somehost:8000")
            with(span) {
                p.resolveConnectionMode() shouldBe ConnectionMode.EXTERNAL
            }
        }

        test("blank URL falls back to auto-detect") {
            val p = provider()
            val expected = if (isExternalDbRunning()) ConnectionMode.EXTERNAL else ConnectionMode.EMBEDDED
            with(span) {
                p.resolveConnectionMode() shouldBe expected
            }
        }
    }

    context("connect") {

        test("creates usable database") {
            val p = provider()
            val db = p.connect()

            val result = db.query("RETURN 1 + 1")
            result.take(0).long shouldBe 2

            db.close()
        }

        test("database has schema applied") {
            val p = provider()
            val db = p.connect()

            val result = db.query("INFO FOR TABLE tag")
            result.take(0).isObject shouldBe true

            db.close()
        }

        test("uses custom namespace and database") {
            val p = provider(namespace = "test_ns", database = "test_db")
            val db = p.connect()

            val result = db.query("RETURN 1 + 1")
            result.take(0).long shouldBe 2

            db.close()
        }
    }
})
