package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Renderer
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import java.nio.file.Files

val GoldenTest by testSuite {
    val runner = Renderer("Vulkan", "llvmpipe (LLVM 20.1.2, 256 bits)", "1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)", "Linux", "amd64")
    val mac = Renderer("OpenGL", "Apple M1 Max", "4.1 Metal - 89.4", "Mac OS X", "aarch64")
    val pinned = PinnedRenderer(mesa = "26.2.5")
    val sidebar = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFF, 0xFFAA00))
    val approved by lazy { Golden(sidebar.sha256, 3, 2, runner) }
    // What an approve keeps of the candidate: the frame's hash and size and the renderer that drew it.
    val approvedKeys by lazy {
        """
        sha256=${sidebar.sha256}
        width=3
        height=2
        backend=Vulkan
        device=llvmpipe (LLVM 20.1.2, 256 bits)
        driver=1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)
        os=Linux
        arch=amd64

        """.trimIndent()
    }

    test("a frame whose every pixel is its golden's matches it") {
        val again = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFF, 0xFFAA00))

        judge(approved, sidebar, again, runner, pinned) shouldBe GoldenVerdict.Matches
    }

    test("a frame one pixel off its golden fails, and its diff image marks that pixel alone") {
        val moved = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFE, 0xFFAA00))

        val differs = judge(approved, sidebar, moved, runner, pinned).shouldBeInstanceOf<GoldenVerdict.Differs>()

        differs.reason shouldBe "1 of 6 pixels differ"
        val diff = checkNotNull(differs.diff)
        val marked = (0 until 2).flatMap { y -> (0 until 3).map { x -> x to y } }.filter { (x, y) -> diff.rgbAt(x, y) == 0xFF0000 }
        marked shouldBe listOf(1 to 1)
    }

    test("a frame off its golden fails without a diff image when the golden's image is not at hand") {
        val moved = Frame(3, 2, intArrayOf(0x7F7F7F, 0x7F7F7F, 0xFFAA00, 0x7F7F7F, 0xFFFFFE, 0xFFAA00))

        val differs = judge(approved, null, moved, runner, pinned).shouldBeInstanceOf<GoldenVerdict.Differs>()

        differs.reason shouldContain "its pixels hash to ${moved.sha256}, the golden's to ${sidebar.sha256}"
        differs.diff shouldBe null
    }

    test("a frame of another size than its golden fails") {
        val larger = Frame(6, 4, IntArray(24) { 0x7F7F7F })

        judge(approved, sidebar, larger, runner, pinned).shouldBeInstanceOf<GoldenVerdict.Differs>().reason shouldBe
            "the frame is 6x4, the golden 3x2"
    }

    test("the pinned renderer is lavapipe Vulkan on Linux x86 with the devenv Mesa, whatever the CPU's vector width") {
        val drawnBy =
            mapOf(
                runner to true,
                runner.copy(device = "llvmpipe (LLVM 20.1.2, 128 bits)") to true,
                runner.copy(driver = "1.4.318 llvmpipe Mesa 26.2.4 (LLVM 20.1.2)") to false,
                runner.copy(driver = "1.4.318 llvmpipe Mesa 26.2.50 (LLVM 20.1.2)") to false,
                runner.copy(backend = "OpenGL") to false,
                runner.copy(device = "AMD Radeon RX 7600 (RADV NAVI33)") to false,
                runner.copy(os = "Mac OS X") to false,
                runner.copy(arch = "aarch64") to false,
                mac to false,
            )

        drawnBy.mapValues { (renderer, _) -> pinned.drew(renderer) } shouldBe drawnBy
    }

    test("on the pinned renderer, a golden another renderer drew fails and asks for a fresh approve") {
        val beforeUpgrade = approved.copy(renderer = runner.copy(driver = "1.4.318 llvmpipe Mesa 26.1.0 (LLVM 20.1.2)"))

        val differs = judge(beforeUpgrade, sidebar, sidebar, runner, pinned).shouldBeInstanceOf<GoldenVerdict.Differs>()

        differs.reason shouldBe
            "the golden was drawn by Vulkan, llvmpipe (LLVM 20.1.2, 256 bits), 1.4.318 llvmpipe Mesa 26.1.0 (LLVM 20.1.2), Linux, " +
            "amd64, and the pinned renderer draws with Vulkan, llvmpipe (LLVM 20.1.2, 256 bits), 1.4.318 llvmpipe Mesa 26.2.5 " +
            "(LLVM 20.1.2), Linux, amd64: re-approve it from this run"
        differs.diff shouldBe null
    }

    test("a machine off the pinned renderer does not check, and the reason names its renderer and the pin") {
        val verdict = judge(approved, sidebar, Frame(3, 2, IntArray(6)), mac, pinned).shouldBeInstanceOf<GoldenVerdict.NotChecked>()

        verdict.reason shouldBe
            "this machine draws with OpenGL, Apple M1 Max, 4.1 Metal - 89.4, Mac OS X, aarch64, not the pinned renderer " +
            "(Vulkan on llvmpipe, Mesa 26.2.5, Linux, amd64)"
    }

    test("on the pinned runner, a frame another renderer drew fails and names the renderer it saw") {
        val onPinnedRunner = PinnedRenderer(mesa = "26.2.5", required = true)
        val drift = Renderer("Vulkan", "llvmpipe (LLVM 20.1.2, 256 bits)", "1.4.318 llvmpipe Mesa 26.3.0 (LLVM 20.1.2)", "Linux", "amd64")

        val verdict = judge(approved, sidebar, sidebar, drift, onPinnedRunner).shouldBeInstanceOf<GoldenVerdict.Differs>()

        verdict.reason shouldBe
            "this is the pinned runner, but it draws with Vulkan, llvmpipe (LLVM 20.1.2, 256 bits), " +
            "1.4.318 llvmpipe Mesa 26.3.0 (LLVM 20.1.2), Linux, amd64, not the pinned renderer " +
            "(Vulkan on llvmpipe, Mesa 26.2.5, Linux, amd64)"
        judge(approved, sidebar, sidebar, runner, onPinnedRunner) shouldBe GoldenVerdict.Matches
    }

    test("on the pinned renderer, a golden never approved fails; off it, it is not checked") {
        judge(null, null, sidebar, runner, pinned) shouldBe GoldenVerdict.Differs("no golden is approved yet", null)
        judge(null, null, sidebar, mac, pinned).shouldBeInstanceOf<GoldenVerdict.NotChecked>()
    }

    test("a frame read back from its PNG holds the same pixels") {
        val png = Files.createTempDirectory("golden").resolve("sidebar.png")

        sidebar.writePng(png)

        Frame.readPng(png).sha256 shouldBe sidebar.sha256
    }

    test("a captured frame's candidate names its golden file, image, hash, size, renderer and whether that is the pinned one") {
        val candidate = Files.createTempDirectory("attempt").resolve("sidebar.golden")

        Golden.writeCandidate(
            candidate,
            "services/playtest/framework/src/gameTest/goldens/sidebar.golden",
            "sidebar.png",
            sidebar,
            runner,
            pinned,
        )

        Files.readString(candidate) shouldBe
            "golden=services/playtest/framework/src/gameTest/goldens/sidebar.golden\nimage=sidebar.png\n" +
            approvedKeys +
            "pinned=true\n"
    }

    test("a golden file holds the hash, size and renderer an approve wrote, and no file holds no golden") {
        val folder = Files.createTempDirectory("goldens")
        Files.writeString(folder.resolve("sidebar.golden"), approvedKeys)

        Golden.read(folder.resolve("sidebar.golden")) shouldBe approved
        Golden.read(folder.resolve("hotbar.golden")) shouldBe null
    }
}
