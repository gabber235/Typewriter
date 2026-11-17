package com.typewritermc.playtest

import build.skir.JsonFlavor
import skirout.harness.v1.golden.Golden
import skirout.harness.v1.golden.GoldenCandidate
import skirout.harness.v1.golden.Renderer
import java.awt.image.BufferedImage
import java.nio.ByteBuffer
import java.nio.file.Files
import java.nio.file.Path
import java.security.MessageDigest
import java.util.HexFormat
import javax.imageio.ImageIO

/**
 * The colours of a drawn frame, row by row from the top, each as `0xRRGGBB`. Alpha never reaches the
 * screen, so a frame holds none. A golden compares frames to the exact pixel.
 */
class Frame(
    val width: Int,
    val height: Int,
    private val rgb: IntArray,
) {
    init {
        require(rgb.size == width * height) { "${width}x$height pixels need ${width * height} colours, not ${rgb.size}" }
    }

    /** The colour at column [x] of row [y], as `0xRRGGBB`. */
    fun rgbAt(
        x: Int,
        y: Int,
    ): Int = rgb[y * width + x]

    /** The SHA-256 of the frame's size and colours, in hex: equal hashes mean equal frames. */
    val sha256: String by lazy {
        val bytes = ByteBuffer.allocate(8 + rgb.size * 3).putInt(width).putInt(height)
        for (colour in rgb) bytes.put((colour shr 16).toByte()).put((colour shr 8).toByte()).put(colour.toByte())
        HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes.array()))
    }

    /** How many pixels show another colour in [other], a frame of the same size. */
    fun differingPixels(other: Frame): Int = rgb.indices.count { rgb[it] != other.rgb[it] }

    /**
     * This frame dimmed to grey, with every pixel that shows another colour in [other] in pure red: no
     * grey pixel is red, so the red ones are exactly the differences.
     */
    fun diff(other: Frame): Frame =
        Frame(
            width,
            height,
            IntArray(rgb.size) { index ->
                if (rgb[index] != other.rgb[index]) {
                    DIFFERS
                } else {
                    val colour = rgb[index]
                    val grey = 64 + ((colour shr 16 and 0xFF) + (colour shr 8 and 0xFF) + (colour and 0xFF)) / 6
                    grey shl 16 or (grey shl 8) or grey
                }
            },
        )

    /** Writes the frame as a PNG to [path]. */
    fun writePng(path: Path) {
        val image = BufferedImage(width, height, BufferedImage.TYPE_INT_RGB)
        image.setRGB(0, 0, width, height, rgb, 0, width)
        path.parent?.let(Files::createDirectories)
        check(ImageIO.write(image, "png", path.toFile())) { "no PNG writer for $path" }
    }

    companion object {
        /** The colour a diff marks a differing pixel with. */
        const val DIFFERS = 0xFF0000

        /** The frame a PNG at [path] holds. */
        fun readPng(path: Path): Frame {
            val image = checkNotNull(ImageIO.read(path.toFile())) { "$path holds no image" }
            val argb = image.getRGB(0, 0, image.width, image.height, null, 0, image.width)
            return Frame(image.width, image.height, IntArray(argb.size) { argb[it] and 0xFFFFFF })
        }
    }
}

/**
 * The renderer goldens are approved on and exact for, the pinned runner's: Vulkan through Mesa's
 * llvmpipe (lavapipe) on Linux x86, with the Mesa devenv ships as [mesa]. The device names the CPU's
 * vector width, which another runner CPU may change, so any llvmpipe device is pinned; a golden still
 * compares only with the exact renderer that drew it. [required] says this machine is the pinned runner
 * (CI's game job), where a frame from any other renderer means the runner drifted from the pin.
 */
class PinnedRenderer(
    private val mesa: String,
    val required: Boolean = false,
) {
    private val mesaRelease = Regex("""(?<![\w.])Mesa ${Regex.escape(mesa)}(?![\w.])""")

    /** Whether [renderer] is the pinned one. */
    fun drew(renderer: Renderer): Boolean =
        renderer.os == "Linux" &&
            renderer.arch == "amd64" &&
            renderer.backend == "Vulkan" &&
            renderer.device.startsWith("llvmpipe (") &&
            mesaRelease.containsMatchIn(renderer.driver)

    override fun toString(): String = "Vulkan on llvmpipe, Mesa $mesa, Linux, amd64"
}

/**
 * A project's goldens: each golden `name` is the file `<folder>/<name>.golden` from the repository
 * [root], a `Golden` as readable Skir JSON, and the frame an approve took for it lies among the local
 * [images] under its hash. They are exact for the [pinned] renderer.
 */
internal class Goldens(
    private val root: Path,
    private val folder: String,
    private val images: Path,
    val pinned: PinnedRenderer,
) {
    /** The file of the golden [name], from the repository root. */
    fun file(name: String): String = "$folder/$name.golden"

    /** The golden [name] approved, or null when none is. */
    fun golden(name: String): Golden? =
        root.resolve(file(name)).takeIf(Files::exists)?.let { Golden.serializer.fromJsonCode(Files.readString(it)) }

    /**
     * Writes to [path], beside a captured frame, what `cargo xtask goldens approve` needs to make it the
     * golden [name]: the frame's PNG [image] in the same folder, its hash and size, its [renderer], and
     * whether that is the pinned one, which approve requires.
     */
    fun writeCandidate(
        path: Path,
        name: String,
        image: String,
        frame: Frame,
        renderer: Renderer,
    ) {
        val candidate =
            GoldenCandidate(
                file = file(name),
                image = image,
                golden = Golden(sha256 = frame.sha256, width = frame.width, height = frame.height, renderer = renderer),
                pinned = pinned.drew(renderer),
            )
        path.parent?.let(Files::createDirectories)
        Files.writeString(path, GoldenCandidate.serializer.toJsonCode(candidate, JsonFlavor.READABLE))
    }

    /** The frame [golden] was approved from, when it lies among the local images. */
    fun image(golden: Golden): Frame? = images.resolve("${golden.sha256}.png").takeIf(Files::exists)?.let(Frame::readPng)
}

/** What comparing a frame with its golden found. */
sealed interface GoldenVerdict {
    /** The frame is the golden, to the pixel. */
    data object Matches : GoldenVerdict

    /** The frame is not the golden: [reason] says how, and [diff] marks the differing pixels when the golden's image was at hand. */
    data class Differs(
        val reason: String,
        val diff: Frame?,
    ) : GoldenVerdict

    /** The frame could not be compared, for [reason]. */
    data class NotChecked(
        val reason: String,
    ) : GoldenVerdict
}

/**
 * Compares [frame], drawn by [renderer], with [golden]. Only the [pinned] renderer checks; there a
 * golden never approved, or one another renderer drew, as before a Mesa upgrade, fails until it is
 * approved. Another renderer passes unchecked, except on the pinned runner, where it fails: every golden
 * would pass unchecked once the runner stopped matching the pin. [image] is the golden's own frame when it is at hand; only then can a difference
 * show where it lies.
 */
fun judge(
    golden: Golden?,
    image: Frame?,
    frame: Frame,
    renderer: Renderer,
    pinned: PinnedRenderer,
): GoldenVerdict {
    if (!pinned.drew(renderer)) {
        if (pinned.required) {
            return GoldenVerdict.Differs(
                "this is the pinned runner, but it draws with ${renderer.named}, not the pinned renderer ($pinned)",
                null,
            )
        }
        return GoldenVerdict.NotChecked("this machine draws with ${renderer.named}, not the pinned renderer ($pinned)")
    }
    if (golden == null) return GoldenVerdict.Differs("no golden is approved yet", null)
    if (golden.renderer != renderer) {
        return GoldenVerdict.Differs(
            "the golden was drawn by ${golden.renderer.named}, and the pinned renderer draws with ${renderer.named}: " +
                "re-approve it from this run",
            null,
        )
    }
    if (frame.width != golden.width || frame.height != golden.height) {
        return GoldenVerdict.Differs("the frame is ${frame.width}x${frame.height}, the golden ${golden.width}x${golden.height}", null)
    }
    if (frame.sha256 == golden.sha256) return GoldenVerdict.Matches
    if (image == null || image.sha256 != golden.sha256) {
        return GoldenVerdict.Differs(
            "its pixels hash to ${frame.sha256}, the golden's to ${golden.sha256}; the golden's image is not at hand to show where",
            null,
        )
    }
    return GoldenVerdict.Differs("${image.differingPixels(frame)} of ${frame.width * frame.height} pixels differ", image.diff(frame))
}

private val Renderer.named: String get() = "$backend, $device, $driver, $os, $arch"
